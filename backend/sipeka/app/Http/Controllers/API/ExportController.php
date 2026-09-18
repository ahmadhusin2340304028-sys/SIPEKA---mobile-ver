<?php
// app/Http/Controllers/API/ExportController.php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Kegiatan;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Worksheet\PageSetup;
use PhpOffice\PhpSpreadsheet\Cell\Coordinate;
use Barryvdh\DomPDF\Facade\Pdf;

class ExportController extends Controller
{
    /**
     * Label kolom tetap di sisi kiri tabel (urutan berpengaruh ke posisi kolom).
     */
    private const FIXED_HEADERS = [
        'NO', 'Bidang', 'Sasaran', 'Indikator', 'Program', 'Kegiatan', 'Sub Kegiatan',
    ];

    /**
     * Label kolom ringkasan di sisi kanan tabel, setelah 12 bulan.
     * Urutan ini mengikuti format laporan realisasi 2026 yang dipakai sebagai acuan.
     */
    private const SUMMARY_HEADERS = [
        'Target Tahunan', 'Satuan', 'Realisasi Kinerja', 'Sisa Target', '% Kinerja',
        'Pagu Tahunan', 'Realisasi Anggaran', 'Sisa Pagu', '% Anggaran',
    ];

    private const BULAN_LABELS = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    /**
     * GET /api/export/excel
     *
     * Query params:
     *   ?bidang=   → filter bidang (opsional)
     *   ?tahun=    → filter tahun (default: tahun sekarang)
     *   ?min_fisik → filter realisasi kinerja minimal (opsional: 30, 50, 90, 100)
     */
    public function excel(Request $request): Response
    {
        $tahun    = $this->resolveTahun($request);
        $kegiatan = $this->fetchKegiatan($request);
        $layout   = $this->buildLayout();

        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Laporan Kegiatan');

        $headerRow = 1;
        $this->writeHeader($sheet, $layout, $headerRow);

        $dataStartRow = $headerRow + 3;
        $no = 1;
        foreach ($kegiatan as $k) {
            $row = $dataStartRow + ($no - 1);
            $this->writeDataRow($sheet, $layout, $row, $no, $k);
            $no++;
        }

        if ($kegiatan->isEmpty()) {
            $this->writeEmptyState($sheet, $layout, $dataStartRow, $tahun);
        }

        $this->applyColumnWidths($sheet, $layout);
        // Kunci baris header saja. Kolom A-G tidak dikunci agar tampilan awal
        // tetap menyatu dari No sampai kolom ringkasan seperti laporan acuan.
        $sheet->freezePane('A' . ($headerRow + 3));
        $sheet->getSheetView()
            ->setZoomScale(55)
            ->setZoomScaleNormal(55);
        $sheet->getPageSetup()
            ->setOrientation(PageSetup::ORIENTATION_LANDSCAPE)
            ->setPaperSize(PageSetup::PAPERSIZE_A3)
            ->setFitToWidth(1)
            ->setFitToHeight(0);
        $sheet->getPageMargins()
            ->setTop(0.3)
            ->setRight(0.2)
            ->setBottom(0.3)
            ->setLeft(0.2);

        $writer = new Xlsx($spreadsheet);
        $filename = "laporan_kegiatan_{$tahun}.xlsx";

        ob_start();
        $writer->save('php://output');
        $content = ob_get_clean();

        return response($content, 200, [
            'Content-Type'        => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
            'Cache-Control'       => 'max-age=0',
        ]);
    }

    /**
     * GET /api/export/pdf
     *
     * Menghasilkan file PDF asli (sebelumnya endpoint ini mengembalikan HTML mentah).
     */
    public function pdf(Request $request): Response
    {
        $kegiatan = $this->fetchKegiatan($request);
        $tahun    = $this->resolveTahun($request);
        $bidang   = $request->input('bidang', 'Semua');

        $html = $this->buildPdfHtml($kegiatan, $tahun, $bidang);

        // Kertas custom lebar (poin) supaya seluruh 40 kolom muat dalam satu lembar,
        // mirip tampilan spreadsheet. Perbesar angka kedua (tinggi) kalau baris kegiatan
        // banyak dan ingin tetap satu halaman per "blok"; dompdf otomatis lanjut halaman
        // baru kalau konten melebihi tinggi kertas.
        $pdf = Pdf::loadHTML($html)->setPaper([0, 0, 2520, 1190]);

        $filename = "laporan_kegiatan_{$tahun}.pdf";

        return response($pdf->output(), 200, [
            'Content-Type'        => 'application/pdf',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
            'Cache-Control'       => 'max-age=0',
        ]);
    }

    // ── Pengambilan data ─────────────────────────────────────────────────

    /**
     * Tahun dan bidang yang tersedia diambil dari data, bukan dari tanggal
     * perangkat. Ini mencegah perangkat bertanggal 2025 hanya menawarkan
     * laporan 2025 saat semua data aktif berada di 2026.
     */
    public function filters(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => [
                'tahun' => Kegiatan::query()
                    ->whereNotNull('tahun')
                    ->distinct()
                    ->orderByDesc('tahun')
                    ->pluck('tahun')
                    ->map(fn ($tahun) => (int) $tahun)
                    ->values(),
                'bidang' => Kegiatan::query()
                    ->whereNotNull('bidang')
                    ->where('bidang', '!=', '')
                    ->distinct()
                    ->orderBy('bidang')
                    ->pluck('bidang')
                    ->values(),
            ],
        ]);
    }

    /**
     * Ambil kegiatan sesuai filter, sudah termasuk filter min_fisik (di-apply
     * di PHP karena total_realisasi_fisik adalah computed attribute).
     *
     * PENTING: buildQuery() SELALU mengembalikan Eloquent Builder (bukan
     * Collection) supaya with()->get() di sini selalu valid. Sebelumnya
     * buildQuery() bisa mengembalikan Collection saat min_fisik>0, yang
     * menyebabkan error "Call to undefined method Collection::with()"
     * setiap kali user memfilter export dengan Realisasi Kinerja Minimal.
     */
    private function fetchKegiatan(Request $request)
    {
        $query    = $this->buildQuery($request);
        $kegiatan = $query->with(['realisasiFisik', 'realisasiAnggaran'])->get();

        if ($request->filled('min_fisik')) {
            $minFisik = (float) $request->input('min_fisik');
            if ($minFisik > 0) {
                $kegiatan = $kegiatan
                    ->filter(fn ($k) => $k->total_realisasi_fisik >= $minFisik)
                    ->values();
            }
        }

        return $kegiatan;
    }

    private function buildQuery(Request $request)
    {
        $tahun  = $this->resolveTahun($request);
        $bidang = $request->input('bidang');

        $query = Kegiatan::where('tahun', $tahun);

        if ($bidang && $bidang !== 'Semua') {
            $query->where('bidang', $bidang);
        }

        return $query
            ->orderBy('bidang')
            ->orderBy('program')
            ->orderBy('kegiatan')
            ->orderBy('sub_kegiatan');
    }

    private function resolveTahun(Request $request): int
    {
        $tahun = filter_var($request->input('tahun'), FILTER_VALIDATE_INT);
        if ($tahun !== false && $tahun >= 2020 && $tahun <= 2099) {
            return $tahun;
        }

        return (int) (Kegiatan::max('tahun') ?: now()->year);
    }

    // ── Layout kolom ─────────────────────────────────────────────────────

    /**
     * Hitung indeks & huruf kolom sekali di satu tempat, supaya tidak ada
     * huruf kolom hardcoded tersebar di banyak baris (rawan salah kalau
     * struktur kolom berubah lagi nanti).
     */
    private function buildLayout(): array
    {
        $numFixed     = count(self::FIXED_HEADERS);   // 7  → A..G
        $monthStart   = $numFixed + 1;                // 8  → H
        $numBulanCols = 24;                           // 12 bulan x (K,A)
        $summaryStart = $monthStart + $numBulanCols;  // 32 → AF

        $bulanKCol = [];
        $bulanACol = [];
        for ($b = 1; $b <= 12; $b++) {
            $bulanKCol[$b] = $monthStart + ($b - 1) * 2;
            $bulanACol[$b] = $bulanKCol[$b] + 1;
        }

        $summaryCols = range($summaryStart, $summaryStart + count(self::SUMMARY_HEADERS) - 1);
        [$colTarget, $colSatuan, $colRealFisik, $colSisaTarget, $colPersenFisik,
         $colPagu, $colRealAnggaran, $colSisaPagu, $colPersenAnggaran] = $summaryCols;

        $totalCols = end($summaryCols); // 40 → AN

        $colLetter = fn (int $idx): string => Coordinate::stringFromColumnIndex($idx);

        return compact(
            'numFixed', 'monthStart', 'numBulanCols', 'summaryStart',
            'bulanKCol', 'bulanACol',
            'colTarget', 'colSatuan', 'colRealFisik', 'colSisaTarget', 'colPersenFisik',
            'colPagu', 'colRealAnggaran', 'colSisaPagu', 'colPersenAnggaran',
            'totalCols', 'colLetter'
        );
    }

    // ── Excel: header ────────────────────────────────────────────────────

    private function writeHeader($sheet, array $layout, int $headerRow): void
    {
        $L = $layout['colLetter'];
        $lastCol = $L($layout['totalCols']);

        // Kolom tetap (rowspan 3)
        foreach (self::FIXED_HEADERS as $i => $label) {
            $colLetter = $L($i + 1);
            $sheet->mergeCells("{$colLetter}{$headerRow}:{$colLetter}" . ($headerRow + 2));
            $sheet->setCellValue("{$colLetter}{$headerRow}", $label);
        }

        // Header "Triwulan N" (colspan 6 = 3 bulan x 2 kolom)
        for ($tw = 0; $tw < 4; $tw++) {
            $startBulan = $tw * 3 + 1;
            $endBulan   = $startBulan + 2;
            $startCol   = $L($layout['bulanKCol'][$startBulan]);
            $endCol     = $L($layout['bulanACol'][$endBulan]);
            $sheet->mergeCells("{$startCol}{$headerRow}:{$endCol}{$headerRow}");
            $sheet->setCellValue("{$startCol}{$headerRow}", 'Triwulan ' . ($tw + 1));
        }

        // Header nama bulan (colspan 2) + sub-header K / A
        foreach (self::BULAN_LABELS as $i => $label) {
            $b = $i + 1;
            $kCol = $L($layout['bulanKCol'][$b]);
            $aCol = $L($layout['bulanACol'][$b]);
            $sheet->mergeCells("{$kCol}" . ($headerRow + 1) . ":{$aCol}" . ($headerRow + 1));
            $sheet->setCellValue("{$kCol}" . ($headerRow + 1), $label);
            $sheet->setCellValue("{$kCol}" . ($headerRow + 2), 'K');
            $sheet->setCellValue("{$aCol}" . ($headerRow + 2), 'A');
        }

        // Kolom ringkasan (rowspan 3)
        foreach (self::SUMMARY_HEADERS as $i => $label) {
            $colLetter = $L($layout['summaryStart'] + $i);
            $sheet->mergeCells("{$colLetter}{$headerRow}:{$colLetter}" . ($headerRow + 2));
            $sheet->setCellValue("{$colLetter}{$headerRow}", $label);
        }

        // Style header
        $sheet->getStyle("A{$headerRow}:{$lastCol}" . ($headerRow + 2))->applyFromArray([
            'font' => ['bold' => true, 'size' => 9, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '1A56DB']],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_CENTER,
                'vertical'   => Alignment::VERTICAL_CENTER,
                'wrapText'   => true,
            ],
            'borders' => [
                'allBorders' => ['borderStyle' => Border::BORDER_THIN, 'color' => ['rgb' => 'FFFFFF']],
            ],
        ]);
        $sheet->getRowDimension($headerRow)->setRowHeight(30);
        $sheet->getRowDimension($headerRow + 1)->setRowHeight(18);
        $sheet->getRowDimension($headerRow + 2)->setRowHeight(16);
    }

    // ── Excel: baris data ────────────────────────────────────────────────

    private function writeDataRow($sheet, array $layout, int $row, int $no, Kegiatan $k): void
    {
        $L = $layout['colLetter'];
        $lastCol = $L($layout['totalCols']);

        $sheet->setCellValue("A{$row}", $no);
        $sheet->setCellValue("B{$row}", $k->bidang);
        $sheet->setCellValue("C{$row}", $k->sasaran_strategis);
        $sheet->setCellValue("D{$row}", $k->indikator_kinerja);
        $sheet->setCellValue("E{$row}", $k->program);
        $sheet->setCellValue("F{$row}", $k->kegiatan);
        $sheet->setCellValue("G{$row}", $k->sub_kegiatan);

        $fisikMap    = $k->realisasiFisik->keyBy('bulan');
        $anggaranMap = $k->realisasiAnggaran->keyBy('bulan');

        for ($b = 1; $b <= 12; $b++) {
            $fisik    = optional($fisikMap->get($b))->nilai;
            $anggaran = optional($anggaranMap->get($b))->nilai;
            $sheet->setCellValue($L($layout['bulanKCol'][$b]) . $row, $fisik !== null ? (float) $fisik : '');
            $sheet->setCellValue($L($layout['bulanACol'][$b]) . $row, $anggaran !== null ? (float) $anggaran : '');
        }

        $target        = (float) $k->target;
        $totalFisik    = $k->total_realisasi_fisik;
        $pagu          = (float) $k->pagu_anggaran;
        $totalAnggaran = $k->total_realisasi_anggaran;

        $sisaTarget     = $target - $totalFisik;
        $persenKinerja  = $target > 0 ? round($totalFisik / $target * 100, 2) : 0;
        $sisaPagu       = $pagu - $totalAnggaran;
        $persenAnggaran = $pagu > 0 ? round($totalAnggaran / $pagu * 100, 2) : 0;

        $sheet->setCellValue($L($layout['colTarget']) . $row, $target);
        $sheet->setCellValue($L($layout['colSatuan']) . $row, $k->satuan);
        $sheet->setCellValue($L($layout['colRealFisik']) . $row, $totalFisik);
        $sheet->setCellValue($L($layout['colSisaTarget']) . $row, $sisaTarget);
        $sheet->setCellValue($L($layout['colPersenFisik']) . $row, $persenKinerja);
        $sheet->setCellValue($L($layout['colPagu']) . $row, $pagu);
        $sheet->setCellValue($L($layout['colRealAnggaran']) . $row, $totalAnggaran);
        $sheet->setCellValue($L($layout['colSisaPagu']) . $row, $sisaPagu);
        $sheet->setCellValue($L($layout['colPersenAnggaran']) . $row, $persenAnggaran);

        // Style baris (warna selang-seling + border)
        $rowBg = ($no % 2 === 0) ? 'F0F4FF' : 'FFFFFF';
        $sheet->getStyle("A{$row}:{$lastCol}{$row}")->applyFromArray([
            'fill'      => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => $rowBg]],
            'borders'   => ['allBorders' => ['borderStyle' => Border::BORDER_THIN, 'color' => ['rgb' => 'CBD5E1']]],
            'alignment' => ['vertical' => Alignment::VERTICAL_CENTER, 'wrapText' => true],
            'font'      => ['size' => 9],
        ]);
        $sheet->getStyle("A{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $sheet->getRowDimension($row)->setRowHeight(24);

        // Format angka — K (fisik) = 2 desimal tetap, A (anggaran) = ribuan tanpa desimal
        for ($b = 1; $b <= 12; $b++) {
            $sheet->getStyle($L($layout['bulanKCol'][$b]) . $row)->getNumberFormat()->setFormatCode('0.00');
            $sheet->getStyle($L($layout['bulanACol'][$b]) . $row)->getNumberFormat()->setFormatCode('#,##0');
        }
        $sheet->getStyle($L($layout['colTarget']) . $row)->getNumberFormat()->setFormatCode('0.00');
        $sheet->getStyle($L($layout['colRealFisik']) . $row)->getNumberFormat()->setFormatCode('0.00');
        $sheet->getStyle($L($layout['colPagu']) . $row)->getNumberFormat()->setFormatCode('#,##0');
        $sheet->getStyle($L($layout['colRealAnggaran']) . $row)->getNumberFormat()->setFormatCode('#,##0');
        $sheet->getStyle($L($layout['colSisaPagu']) . $row)->getNumberFormat()->setFormatCode('#,##0');
        // Sisa Target, % Kinerja, % Anggaran sengaja TIDAK diberi format khusus
        // (dibiarkan "General") supaya tampilannya persis seperti laporan referensi:
        // tanpa nol di belakang koma dan tanpa simbol "%" ikut tercetak di sel.
    }

    private function writeEmptyState($sheet, array $layout, int $row, int $tahun): void
    {
        $L = $layout['colLetter'];
        $lastCol = $L($layout['totalCols']);

        $sheet->mergeCells("A{$row}:{$lastCol}{$row}");
        $sheet->setCellValue("A{$row}", "Tidak ada data kegiatan untuk tahun {$tahun}.");
        $sheet->getStyle("A{$row}:{$lastCol}{$row}")->applyFromArray([
            'font'      => ['bold' => true, 'size' => 9],
            'fill'      => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => 'FEF3C7']],
            'borders'   => ['allBorders' => ['borderStyle' => Border::BORDER_THIN, 'color' => ['rgb' => 'F59E0B']]],
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER, 'vertical' => Alignment::VERTICAL_CENTER],
        ]);
        $sheet->getRowDimension($row)->setRowHeight(24);
    }

    private function applyColumnWidths($sheet, array $layout): void
    {
        $L = $layout['colLetter'];

        $sheet->getColumnDimension('A')->setWidth(5);
        $sheet->getColumnDimension('B')->setWidth(16);
        $sheet->getColumnDimension('C')->setWidth(18);
        $sheet->getColumnDimension('D')->setWidth(18);
        $sheet->getColumnDimension('E')->setWidth(16);
        $sheet->getColumnDimension('F')->setWidth(16);
        $sheet->getColumnDimension('G')->setWidth(18);

        for ($idx = $layout['monthStart']; $idx < $layout['summaryStart']; $idx++) {
            $sheet->getColumnDimension($L($idx))->setWidth(8);
        }

        $sheet->getColumnDimension($L($layout['colTarget']))->setWidth(11);
        $sheet->getColumnDimension($L($layout['colSatuan']))->setWidth(9);
        $sheet->getColumnDimension($L($layout['colRealFisik']))->setWidth(12);
        $sheet->getColumnDimension($L($layout['colSisaTarget']))->setWidth(11);
        $sheet->getColumnDimension($L($layout['colPersenFisik']))->setWidth(9);
        $sheet->getColumnDimension($L($layout['colPagu']))->setWidth(14);
        $sheet->getColumnDimension($L($layout['colRealAnggaran']))->setWidth(14);
        $sheet->getColumnDimension($L($layout['colSisaPagu']))->setWidth(14);
        $sheet->getColumnDimension($L($layout['colPersenAnggaran']))->setWidth(10);
    }

    // ── PDF ──────────────────────────────────────────────────────────────

    private function buildPdfHtml($kegiatan, $tahun, $bidang): string
    {
        $bulanHeaders = '';
        foreach (self::BULAN_LABELS as $bl) {
            $bulanHeaders .= "<th colspan='2'>{$bl}</th>";
        }
        $kaHeaders = str_repeat('<th>K</th><th>A</th>', 12);

        $fixedHeaderCells = '';
        foreach (self::FIXED_HEADERS as $label) {
            $fixedHeaderCells .= "<th rowspan='3'>{$label}</th>";
        }
        $summaryHeaderCells = '';
        foreach (self::SUMMARY_HEADERS as $label) {
            $summaryHeaderCells .= "<th rowspan='3'>{$label}</th>";
        }

        $rows = '';
        $no = 1;
        foreach ($kegiatan as $k) {
            $fisikMap    = $k->realisasiFisik->keyBy('bulan');
            $anggaranMap = $k->realisasiAnggaran->keyBy('bulan');

            $bulanCells = '';
            for ($b = 1; $b <= 12; $b++) {
                $f = optional($fisikMap->get($b))->nilai;
                $a = optional($anggaranMap->get($b))->nilai;
                $fFmt = $f !== null ? number_format((float) $f, 2, '.', '') : '';
                $aFmt = $a !== null ? number_format((float) $a, 0, ',', '.') : '';
                $bulanCells .= "<td class='num'>{$fFmt}</td><td class='num'>{$aFmt}</td>";
            }

            $target        = (float) $k->target;
            $totalFisik    = $k->total_realisasi_fisik;
            $pagu          = (float) $k->pagu_anggaran;
            $totalAnggaran = $k->total_realisasi_anggaran;

            $sisaTarget     = $target - $totalFisik;
            $persenKinerja  = $target > 0 ? round($totalFisik / $target * 100, 2) : 0;
            $sisaPagu       = $pagu - $totalAnggaran;
            $persenAnggaran = $pagu > 0 ? round($totalAnggaran / $pagu * 100, 2) : 0;

            $targetFmt        = number_format($target, 2, '.', '');
            $realFisikFmt     = number_format($totalFisik, 2, '.', '');
            $paguFmt          = number_format($pagu, 0, ',', '.');
            $realAnggaranFmt  = number_format($totalAnggaran, 0, ',', '.');
            $sisaPaguFmt      = number_format($sisaPagu, 0, ',', '.');

            $bgColor = ($no % 2 === 0) ? '#F0F4FF' : '#FFFFFF';
            $rows .= "
            <tr style='background:{$bgColor}'>
                <td class='num'>{$no}</td>
                <td>{$this->escape($k->bidang)}</td>
                <td>{$this->escape($k->sasaran_strategis)}</td>
                <td>{$this->escape($k->indikator_kinerja)}</td>
                <td>{$this->escape($k->program)}</td>
                <td>{$this->escape($k->kegiatan)}</td>
                <td>{$this->escape($k->sub_kegiatan)}</td>
                {$bulanCells}
                <td class='num'>{$targetFmt}</td>
                <td>{$this->escape($k->satuan)}</td>
                <td class='num'>{$realFisikFmt}</td>
                <td class='num'>{$sisaTarget}</td>
                <td class='num'>{$persenKinerja}</td>
                <td class='num'>{$paguFmt}</td>
                <td class='num'>{$realAnggaranFmt}</td>
                <td class='num'>{$sisaPaguFmt}</td>
                <td class='num'>{$persenAnggaran}</td>
            </tr>";
            $no++;
        }

        if ($kegiatan->isEmpty()) {
            $columnCount = count(self::FIXED_HEADERS) + 24 + count(self::SUMMARY_HEADERS);
            $rows = "<tr><td colspan='{$columnCount}' class='empty'>Tidak ada data kegiatan untuk tahun {$tahun}.</td></tr>";
        }

        $printedAt  = now()->format('d/m/Y H:i');
        $totalCount = $no - 1;

        return <<<HTML
<!DOCTYPE html>
<html>
<head>
<meta charset='UTF-8'>
<style>
  @page { margin: 14px; }
  body { font-family: Arial, sans-serif; font-size: 6.5pt; margin: 0; }
  h2 { text-align: center; font-size: 11pt; margin: 0; }
  h4 { text-align: center; font-size: 9pt; color: #555; margin: 4px 0 10px; }
  table { width: 100%; border-collapse: collapse; }
  thead { display: table-header-group; }
  tr { page-break-inside: avoid; }
  th { background: #1A56DB; color: #fff; padding: 4px 3px; text-align: center;
       border: 1px solid #93C5FD; font-size: 6.5pt; }
  td { padding: 3px 4px; border: 1px solid #CBD5E1; font-size: 6.5pt; }
  td.num { text-align: right; }
  td.empty { padding: 10px; text-align: center; font-weight: bold; color: #92400E; background: #FEF3C7; }
</style>
</head>
<body>
<h2>LAPORAN REALISASI KINERJA DAN ANGGARAN KEGIATAN TAHUN {$tahun}</h2>
<h4>Bidang: {$this->escape($bidang)}</h4>
<table>
  <thead>
    <tr>
      {$fixedHeaderCells}
      <th colspan='6'>Triwulan 1</th>
      <th colspan='6'>Triwulan 2</th>
      <th colspan='6'>Triwulan 3</th>
      <th colspan='6'>Triwulan 4</th>
      {$summaryHeaderCells}
    </tr>
    <tr>{$bulanHeaders}</tr>
    <tr>{$kaHeaders}</tr>
  </thead>
  <tbody>{$rows}</tbody>
</table>
<p style='margin-top:10px;font-size:8pt;color:#666'>
  Dicetak: {$printedAt} | Total kegiatan: {$totalCount}
</p>
</body>
</html>
HTML;
    }

    private function escape(mixed $value): string
    {
        return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
    }
}
