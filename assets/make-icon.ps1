Add-Type -AssemblyName System.Drawing
$out = $args[0]
$preview = $args[1]

function Draw-Logo([int]$s) {
    $bmp = New-Object System.Drawing.Bitmap $s, $s
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $k = $s / 256.0

    # shield shape
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddBezier(128*$k, 14*$k, 170*$k, 36*$k, 200*$k, 40*$k, 226*$k, 40*$k)
    $p.AddBezier(226*$k, 40*$k, 232*$k, 150*$k, 200*$k, 210*$k, 128*$k, 244*$k)
    $p.AddBezier(128*$k, 244*$k, 56*$k, 210*$k, 24*$k, 150*$k, 30*$k, 40*$k)
    $p.AddBezier(30*$k, 40*$k, 56*$k, 40*$k, 86*$k, 36*$k, 128*$k, 14*$k)
    $p.CloseFigure()

    $rect = New-Object System.Drawing.RectangleF 0, 0, $s, $s
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(255,170,200)), ([System.Drawing.Color]::FromArgb(190,150,245)), 90
    $g.FillPath($grad, $p)
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120, 80, 60, 110)), ([Math]::Max(1, 8*$k))
    $pen.LineJoin = 'Round'
    $g.DrawPath($pen, $p)

    $ink = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(80, 55, 90))
    $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $blush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(150, 255, 110, 150))

    # eyes + sparkle
    $g.FillEllipse($ink, 84*$k, 104*$k, 26*$k, 30*$k)
    $g.FillEllipse($ink, 146*$k, 104*$k, 26*$k, 30*$k)
    if ($s -ge 32) {
        $g.FillEllipse($white, 92*$k, 108*$k, 9*$k, 9*$k)
        $g.FillEllipse($white, 154*$k, 108*$k, 9*$k, 9*$k)
    }
    # blush
    $g.FillEllipse($blush, 62*$k, 138*$k, 34*$k, 18*$k)
    $g.FillEllipse($blush, 160*$k, 138*$k, 34*$k, 18*$k)
    # smile
    $sp = New-Object System.Drawing.Pen $ink.Color, ([Math]::Max(1.5, 8*$k))
    $sp.StartCap = 'Round'; $sp.EndCap = 'Round'
    $g.DrawArc($sp, 112*$k, 128*$k, 32*$k, 26*$k, 20, 140)

    # little toggle pill at the bottom
    if ($s -ge 48) {
        $tp = New-Object System.Drawing.Drawing2D.GraphicsPath
        $tp.AddArc(96*$k, 178*$k, 28*$k, 28*$k, 90, 180)
        $tp.AddArc(132*$k, 178*$k, 28*$k, 28*$k, 270, 180)
        $tp.CloseFigure()
        $g.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120,214,170))), $tp)
        $g.FillEllipse($white, 134*$k, 181*$k, 22*$k, 22*$k)
    }

    # sparkles
    $star = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 215, 90))
    foreach ($st in @(@(222, 22, 18), @(28, 196, 12))) {
        if ($s -lt 48) { break }
        $cx = $st[0]*$k; $cy = $st[1]*$k; $r = $st[2]*$k; $q = $r * 0.28
        $pts = [System.Drawing.PointF[]]@(
            (New-Object System.Drawing.PointF $cx, ($cy-$r)), (New-Object System.Drawing.PointF ($cx+$q), ($cy-$q)),
            (New-Object System.Drawing.PointF ($cx+$r), $cy), (New-Object System.Drawing.PointF ($cx+$q), ($cy+$q)),
            (New-Object System.Drawing.PointF $cx, ($cy+$r)), (New-Object System.Drawing.PointF ($cx-$q), ($cy+$q)),
            (New-Object System.Drawing.PointF ($cx-$r), $cy), (New-Object System.Drawing.PointF ($cx-$q), ($cy-$q)))
        $g.FillPolygon($star, $pts)
    }
    $g.Dispose()
    return $bmp
}

$sizes = 16, 24, 32, 48, 64, 128, 256
$pngs = foreach ($sz in $sizes) {
    $b = Draw-Logo $sz
    if ($sz -eq 256) { $b.Save($preview, [System.Drawing.Imaging.ImageFormat]::Png) }
    $ms = New-Object System.IO.MemoryStream
    $b.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    ,$ms.ToArray()
}

$fs = [System.IO.File]::Create($out)
$w = New-Object System.IO.BinaryWriter $fs
$w.Write([UInt16]0); $w.Write([UInt16]1); $w.Write([UInt16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $d = if ($sizes[$i] -ge 256) { 0 } else { $sizes[$i] }
    $w.Write([byte]$d); $w.Write([byte]$d); $w.Write([byte]0); $w.Write([byte]0)
    $w.Write([UInt16]1); $w.Write([UInt16]32)
    $w.Write([UInt32]$pngs[$i].Length); $w.Write([UInt32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($png in $pngs) { $w.Write($png) }
$w.Close()
