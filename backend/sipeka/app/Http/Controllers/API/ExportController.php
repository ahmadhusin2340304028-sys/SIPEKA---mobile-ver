<?php
// app/Http/Controllers/API/ExportController.php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Kegiatan;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Style\Font;
use PhpOffice\PhpSpreadsheet\Cell\DataType;

class ExportController extends Controller
{
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
        $query = $this->buildQuery($request);
        $kegiatan = $query->with(['realisasiFisik', 'realisasiAnggaran'])->get();

        if ($request->filled('min_fisik')) {
            $minFisik = (float) $request->input('min_fisik');
            if ($minFisik > 0) {
                $kegiatan = $kegiatan->filter(function ($k) use ($minFisik) {
                    return $k->total_realisasi_fisik >= $minFisik;
                });
            }
        }

        $spreadsheet = new Spreadsheet();
        $sheet = $spreadsheet->getActiveSheet();
        $sheet->setTitle('Laporan Kegiatan');

        $tahun = $request->input('tahun', date('Y'));
        $bidang = $request->input('bidang', 'Semua');

        // ── Judul ──────────────────────────────────────────────────────────
        $sheet->mergeCells('A1:AM1');
        $sheet->setCellValue('A1', "LAPORAN REALISASI KINERJA DAN ANGGARAN KEGIATAN TAHUN {$tahun}");
        $sheet->getStyle('A1')->applyFromArray([
            'font' => ['bold' => true, 'size' => 13],
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
        ]);

        $sheet->mergeCells('A2:AM2');
        $sheet->setCellValue('A2', $bidang !== 'Semua' ? "Bidang: {$bidang}" : 'Semua Bidang');
        $sheet->getStyle('A2')->applyFromArray([
            'font' => ['size' => 10, 'italic' => true],
            'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER],
        ]);

        // ── Header Row 1 ───────────────────────────────────────────────────
        // Kolom: A=NO, B=Bidang, C=Sasaran, D=Indikator, E=Program, F=Kegiatan, G=Sub Kegiatan
        // H-S = Triwulan 1 (Jan–Mar, 6 col), T-Y = Triwulan 2, Z-AE = Triwulan 3, AF-AQ = Triwulan 4
        // AR=Target, AS=Realisasi Kinerja, AT=Sisa Target, AU=% Kinerja
        // AV=Pagu, AW=Realisasi Anggaran, AX=Sisa Pagu, AY=% Anggaran

        $headerRow = 4;

        // Fixed columns (rowspan 3)
        $fixedHeaders = [
            'A' => 'NO', 'B' => 'Bidang', 'C' => 'Sasaran Strategis',
            'D' => 'Indikator Kinerja', 'E' => 'Program', 'F' => 'Kegiatan',
            'G' => 'Sub Kegiatan',
        ];
        foreach ($fixedHeaders as $col => $label) {
            $sheet->mergeCells("{$col}{$headerRow}:{$col}" . ($headerRow + 2));
            $sheet->setCellValue("{$col}{$headerRow}", $label);
        }

        // Triwulan headers (colspan 6)
        $triwulanCols = ['H', 'N', 'T', 'Z'];
        $triwulanEndCols = ['M', 'S', 'Y', 'AE'];
        for ($i = 0; $i < 4; $i++) {
            $sheet->mergeCells("{$triwulanCols[$i]}{$headerRow}:{$triwulanEndCols[$i]}{$headerRow}");
            $sheet->setCellValue("{$triwulanCols[$i]}{$headerRow}", "Triwulan " . ($i + 1));
        }

        // Summary cols (rowspan 3)
        $summaryHeaders = [
            'AF' => 'Target Tahunan', 'AG' => 'Realisasi Kinerja',
            'AH' => 'Sisa Target', 'AI' => '% Kinerja',
            'AJ' => 'Pagu Tahunan (Rp)', 'AK' => 'Realisasi Anggaran (Rp)',
            'AL' => 'Sisa Pagu (Rp)', 'AM' => '% Anggaran',
        ];
        foreach ($summaryHeaders as $col => $label) {
            $sheet->mergeCells("{$col}{$headerRow}:{$col}" . ($headerRow + 2));
            $sheet->setCellValue("{$col}{$headerRow}", $label);
        }

        // ── Header Row 2: bulan (colspan 2 per bulan) ─────────────────────
        $bulanLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
        $bulanCols = ['H', 'J', 'L', 'N', 'P', 'R', 'T', 'V', 'X', 'Z', 'AB', 'AD'];
        $bulanEndCols = ['I', 'K', 'M', 'O', 'Q', 'S', 'U', 'W', 'Y', 'AA', 'AC', 'AE'];
        for ($i = 0; $i < 12; $i++) {
            $sheet->mergeCells("{$bulanCols[$i]}" . ($headerRow + 1) . ":{$bulanEndCols[$i]}" . ($headerRow + 1));
            $sheet->setCellValue("{$bulanCols[$i]}" . ($headerRow + 1), $bulanLabels[$i]);
        }

        // ── Header Row 3: K / A per bulan ─────────────────────────────────
        $subCols = [];
        $colLetters = range('H', 'Z'); // H to AE
        // Build full column list H..AE
        $allBulanCols = [];
        for ($i = 0; $i < 12; $i++) {
            $allBulanCols[] = [$bulanCols[$i], $bulanEndCols[$i]];
        }
        foreach ($allBulanCols as [$kCol, $aCol]) {
            $sheet->setCellValue("{$kCol}" . ($headerRow + 2), 'K');
            $sheet->setCellValue("{$aCol}" . ($headerRow + 2), 'A');
        }

        // ── Style header ───────────────────────────────────────────────────
        $headerStyle = [
            'font' => ['bold' => true, 'size' => 9, 'color' => ['rgb' => 'FFFFFF']],
            'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => '1A56DB']],
            'alignment' => [
                'horizontal' => Alignment::HORIZONTAL_CENTER,
                'vertical' => Alignment::VERTICAL_CENTER,
                'wrapText' => true,
            ],
            'borders' => [
                'allBorders' => ['borderStyle' => Border::BORDER_THIN, 'color' => ['rgb' => 'FFFFFF']],
            ],
        ];
        $sheet->getStyle("A{$headerRow}:AM" . ($headerRow + 2))->applyFromArray($headerStyle);
        $sheet->getRowDimension($headerRow)->setRowHeight(30);
        $sheet->getRowDimension($headerRow + 1)->setRowHeight(18);
        $sheet->getRowDimension($headerRow + 2)->setRowHeight(16);

        // ── Data rows ──────────────────────────────────────────────────────
        $dataStartRow = $headerRow + 3;
        $no = 1;

        foreach ($kegiatan as $k) {
            $row = $dataStartRow + ($no - 1);

            // Build per-bulan map
            $fisikMap = $k->realisasiFisik->keyBy('bulan');
            $anggaranMap = $k->realisasiAnggaran->keyBy('bulan');

            $sheet->setCellValue("A{$row}", $no);
            $sheet->setCellValue("B{$row}", $k->bidang);
            $sheet->setCellValue("C{$row}", $k->sasaran_strategis);
            $sheet->setCellValue("D{$row}", $k->indikator_kinerja);
            $sheet->setCellValue("E{$row}", $k->program);
            $sheet->setCellValue("F{$row}", $k->kegiatan);
            $sheet->setCellValue("G{$row}", $k->sub_kegiatan);

            // Per-bulan data (K = fisik, A = anggaran)
            for ($bulan = 1; $bulan <= 12; $bulan++) {
                [$kCol, $aCol] = $allBulanCols[$bulan - 1];
                $fisik = optional($fisikMap->get($bulan))->nilai;
                $anggaran = optional($anggaranMap->get($bulan))->nilai;
                $sheet->setCellValue("{$kCol}{$row}", $fisik !== null ? (float)$fisik : '');
                $sheet->setCellValue("{$aCol}{$row}", $anggaran !== null ? (float)$anggaran : '');
            }

            // Summary columns
            $totalFisik = $k->total_realisasi_fisik;
            $totalAnggaran = $k->total_realisasi_anggaran;
            $target = (float)$k->target;
            $pagu = (float)$k->pagu_anggaran;
            $sisaTarget = $target - $totalFisik;
            $pctKinerja = $target > 0 ? round($totalFisik / $target * 100, 2) : 0;
            $sisaPagu = $pagu - $totalAnggaran;
            $pctAnggaran = $pagu > 0 ? round($totalAnggaran / $pagu * 100, 2) : 0;

            $sheet->setCellValue("AF{$row}", $target);
            $sheet->setCellValue("AG{$row}", $totalFisik);
            $sheet->setCellValue("AH{$row}", $sisaTarget);
            $sheet->setCellValue("AI{$row}", $pctKinerja);
            $sheet->setCellValue("AJ{$row}", $pagu);
            $sheet->setCellValue("AK{$row}", $totalAnggaran);
            $sheet->setCellValue("AL{$row}", $sisaPagu);
            $sheet->setCellValue("AM{$row}", $pctAnggaran);

            // Row style
            $rowBg = ($no % 2 === 0) ? 'F0F4FF' : 'FFFFFF';
            $sheet->getStyle("A{$row}:AM{$row}")->applyFromArray([
                'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => $rowBg]],
                'borders' => ['allBorders' => ['borderStyle' => Border::BORDER_THIN, 'color' => ['rgb' => 'CBD5E1']]],
                'alignment' => ['vertical' => Alignment::VERTICAL_CENTER, 'wrapText' => true],
                'font' => ['size' => 9],
            ]);
            $sheet->getStyle("A{$row}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
            $sheet->getRowDimension($row)->setRowHeight(24);

            // Currency format for anggaran columns
            $currencyFormat = '#,##0';
            foreach ([$aCol] as $ignored) {
                for ($b = 1; $b <= 12; $b++) {
                    $aC = $allBulanCols[$b - 1][1];
                    $sheet->getStyle("{$aC}{$row}")->getNumberFormat()->setFormatCode($currencyFormat);
                }
            }
            $sheet->getStyle("AJ{$row}:AL{$row}")->getNumberFormat()->setFormatCode($currencyFormat);
            $sheet->getStyle("AI{$row}")->getNumberFormat()->setFormatCode('0.00"%"');
            $sheet->getStyle("AM{$row}")->getNumberFormat()->setFormatCode('0.00"%"');

            $no++;
        }

        // ── Totals row ─────────────────────────────────────────────────────
        if ($no > 1) {
            $totalRow = $dataStartRow + ($no - 1);
            $lastDataRow = $totalRow - 1;

            $sheet->mergeCells("A{$totalRow}:G{$totalRow}");
            $sheet->setCellValue("A{$totalRow}", 'TOTAL');
            $sheet->getStyle("A{$totalRow}:AM{$totalRow}")->applyFromArray([
                'font' => ['bold' => true, 'size' => 9],
                'fill' => ['fillType' => Fill::FILL_SOLID, 'startColor' => ['rgb' => 'DBEAFE']],
                'borders' => ['allBorders' => ['borderStyle' => Border::BORDER_THIN, 'color' => ['rgb' => '93C5FD']]],
                'alignment' => ['horizontal' => Alignment::HORIZONTAL_CENTER, 'vertical' => Alignment::VERTICAL_CENTER],
            ]);

            $sheet->setCellValue("AJ{$totalRow}", "=SUM(AJ{$dataStartRow}:AJ{$lastDataRow})");
            $sheet->setCellValue("AK{$totalRow}", "=SUM(AK{$dataStartRow}:AK{$lastDataRow})");
            $sheet->setCellValue("AL{$totalRow}", "=SUM(AL{$dataStartRow}:AL{$lastDataRow})");
            $sheet->getStyle("AJ{$totalRow}:AL{$totalRow}")->getNumberFormat()->setFormatCode('#,##0');
        }

        // ── Column widths ──────────────────────────────────────────────────
        $sheet->getColumnDimension('A')->setWidth(5);
        $sheet->getColumnDimension('B')->setWidth(22);
        $sheet->getColumnDimension('C')->setWidth(28);
        $sheet->getColumnDimension('D')->setWidth(28);
        $sheet->getColumnDimension('E')->setWidth(22);
        $sheet->getColumnDimension('F')->setWidth(22);
        $sheet->getColumnDimension('G')->setWidth(28);
        foreach (['H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','AA','AB','AC','AD','AE'] as $col) {
            $sheet->getColumnDimension($col)->setWidth(10);
        }
        foreach (['AF','AG','AH'] as $col) {
            $sheet->getColumnDimension($col)->setWidth(12);
        }
        $sheet->getColumnDimension('AI')->setWidth(10);
        foreach (['AJ','AK','AL'] as $col) {
            $sheet->getColumnDimension($col)->setWidth(18);
        }
        $sheet->getColumnDimension('AM')->setWidth(10);

        $sheet->freezePane('H' . ($headerRow + 3));

        // ── Output ────────────────────────────────────────────────────────
        $writer = new Xlsx($spreadsheet);
        $filename = "laporan_kegiatan_{$tahun}.xlsx";

        ob_start();
        $writer->save('php://output');
        $content = ob_get_clean();

        return response($content, 200, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
            'Cache-Control' => 'max-age=0',
        ]);
    }

    /**
     * GET /api/export/pdf
     */
    public function pdf(Request $request): Response
    {
        $query = $this->buildQuery($request);
        $kegiatan = $query->with(['realisasiFisik', 'realisasiAnggaran'])->get();

        if ($request->filled('min_fisik')) {
            $minFisik = (float) $request->input('min_fisik');
            if ($minFisik > 0) {
                $kegiatan = $kegiatan->filter(function ($k) use ($minFisik) {
                    return $k->total_realisasi_fisik >= $minFisik;
                });
            }
        }

        $tahun = $request->input('tahun', date('Y'));
        $bidang = $request->input('bidang', 'Semua');
        $bulanLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];

        $rows = '';
        $no = 1;
        foreach ($kegiatan as $k) {
            $fisikMap = $k->realisasiFisik->keyBy('bulan');
            $anggaranMap = $k->realisasiAnggaran->keyBy('bulan');

            $bulanCells = '';
            for ($b = 1; $b <= 12; $b++) {
                $f = optional($fisikMap->get($b))->nilai ?? '-';
                $a = optional($anggaranMap->get($b))->nilai;
                $aFmt = $a ? number_format((float)$a, 0, ',', '.') : '-';
                $bulanCells .= "<td style='text-align:center'>{$f}</td><td style='text-align:right'>{$aFmt}</td>";
            }

            $totalFisik = $k->total_realisasi_fisik;
            $totalAnggaran = $k->total_realisasi_anggaran;
            $target = (float)$k->target;
            $pagu = (float)$k->pagu_anggaran;
            $pctKinerja = $target > 0 ? round($totalFisik / $target * 100, 2) : 0;
            $pctAnggaran = $pagu > 0 ? round($totalAnggaran / $pagu * 100, 2) : 0;

            $bgColor = ($no % 2 === 0) ? '#F0F4FF' : '#FFFFFF';
            $rows .= "
            <tr style='background:{$bgColor}'>
                <td style='text-align:center'>{$no}</td>
                <td>{$k->bidang}</td>
                <td>{$k->sub_kegiatan}</td>
                {$bulanCells}
                <td style='text-align:right'>{$target}</td>
                <td style='text-align:right'>{$totalFisik}</td>
                <td style='text-align:right'>" . round($target - $totalFisik, 2) . "</td>
                <td style='text-align:right'>{$pctKinerja}%</td>
                <td style='text-align:right'>" . number_format($pagu, 0, ',', '.') . "</td>
                <td style='text-align:right'>" . number_format($totalAnggaran, 0, ',', '.') . "</td>
                <td style='text-align:right'>" . number_format($pagu - $totalAnggaran, 0, ',', '.') . "</td>
                <td style='text-align:right'>{$pctAnggaran}%</td>
            </tr>";
            $no++;
        }

        $bulanHeaders = '';
        foreach ($bulanLabels as $bl) {
            $bulanHeaders .= "<th colspan='2'>{$bl}</th>";
        }
        $kaHeaders = str_repeat('<th>K</th><th>A</th>', 12);

        $html = <<<HTML
<!DOCTYPE html>
<html>
<head>
<meta charset='UTF-8'>
<style>
  body { font-family: Arial, sans-serif; font-size: 7pt; margin: 10px; }
  h2 { text-align: center; font-size: 11pt; margin: 0; }
  h4 { text-align: center; font-size: 9pt; color: #555; margin: 4px 0 10px; }
  table { width: 100%; border-collapse: collapse; }
  th { background: #1A56DB; color: #fff; padding: 4px 3px; text-align: center;
       border: 1px solid #93C5FD; font-size: 7pt; }
  td { padding: 3px 4px; border: 1px solid #CBD5E1; font-size: 7pt; }
  .total { background: #DBEAFE; font-weight: bold; }
</style>
</head>
<body>
<h2>LAPORAN REALISASI KINERJA DAN ANGGARAN KEGIATAN TAHUN {$tahun}</h2>
<h4>Bidang: {$bidang}</h4>
<table>
  <thead>
    <tr>
      <th rowspan='3'>NO</th>
      <th rowspan='3'>Bidang</th>
      <th rowspan='3'>Sub Kegiatan</th>
      {$bulanHeaders}
      <th rowspan='3'>Target</th>
      <th rowspan='3'>Real. Kinerja</th>
      <th rowspan='3'>Sisa Target</th>
      <th rowspan='3'>% Kinerja</th>
      <th rowspan='3'>Pagu (Rp)</th>
      <th rowspan='3'>Real. Anggaran (Rp)</th>
      <th rowspan='3'>Sisa Pagu (Rp)</th>
      <th rowspan='3'>% Anggaran</th>
    </tr>
    <tr>{$kaHeaders}</tr>
  </thead>
  <tbody>{$rows}</tbody>
</table>
<p style='margin-top:10px;font-size:8pt;color:#666'>
  Dicetak: " . now()->format('d/m/Y H:i') . " | Total kegiatan: " . ($no - 1) . "
</p>
</body>
</html>
HTML;

        return response($html, 200, [
            'Content-Type' => 'text/html; charset=UTF-8',
            'X-Export-Type' => 'pdf-html',
        ]);
    }

    // ── Helper ────────────────────────────────────────────────────────────

    private function buildQuery(Request $request)
    {
        $tahun = $request->input('tahun', date('Y'));
        $bidang = $request->input('bidang');
        $minFisik = $request->input('min_fisik');

        $query = Kegiatan::where('tahun', $tahun);

        if ($bidang && $bidang !== 'Semua') {
            $query->where('bidang', $bidang);
        }

        if ($minFisik !== null) {
            $minFisik = (float) $minFisik;
            // Filter di PHP setelah load (karena total_realisasi_fisik adalah computed attribute)
            // Untuk performa, kita filter via subquery jika diperlukan
            // Tapi untuk simplicity, kita filter di PHP
        }

        $result = $query->orderBy('bidang')->orderBy('sub_kegiatan');

        if ($minFisik !== null && $minFisik > 0) {
            return $result->get()->filter(function ($k) use ($minFisik) {
                return $k->total_realisasi_fisik >= $minFisik;
            });
        }

        return $result;
    }
}