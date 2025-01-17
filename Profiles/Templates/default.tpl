<chart>
id=133740744144747444
symbol=USDCHF
description=US Dollar vs Swiss Franc
period_type=0
period_size=1
digits=5
tick_size=0.000000
position_time=1732003200
scale_fix=0
scale_fixed_min=0.914100
scale_fixed_max=0.919000
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=32
mode=1
fore=0
grid=0
volume=0
scroll=1
shift=1
shift_size=20.879121
fixed_pos=0.000000
ticker=1
ohlc=0
one_click=0
one_click_btn=0
bidline=1
askline=1
lastline=0
days=0
descriptions=0
tradelines=1
tradehistory=1
window_left=852
window_top=0
window_right=1704
window_bottom=1097
window_type=3
floating=0
floating_left=0
floating_top=0
floating_right=0
floating_bottom=0
floating_type=1
floating_toolbar=1
floating_tbstate=
background_color=15134970
foreground_color=0
barup_color=0
bardown_color=0
bullcandle_color=16777215
bearcandle_color=0
chartline_color=0
volumes_color=32768
grid_color=12632256
bidline_color=12632256
askline_color=12632256
lastline_color=12632256
stops_color=17919
windows_total=1

<expert>
name=HINNmagicEntry
path=Experts\Market\HINNmagicEntry.ex5
expertmode=5
<inputs>
=
x_size=80
y_size=60
bFontSizeBig=10
bFontSizeSmall=10
=
_Risk=2
risk=1.0
risk_step=0.5
close_now=50
=
add_spread=false
position_SPLIT=false
activekeyboard=false
audio=false
</inputs>
</expert>

<window>
height=100.000000
objects=29

<indicator>
name=Main
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1
</indicator>

<indicator>
name=Custom Indicator
path=Indicators\Market\Candle Timer Countdown.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=36
fixed_height=-1

<graph>
name=COUNTDOWN COLOR
draw=0
style=0
width=1
arrow=251
color=13828244
</graph>
<inputs>
eBaseCorner=2
xDISTANCE=1
yDISTANCE=1
fontSize=8
showPerc=false
</inputs>
</indicator>

<indicator>
name=Custom Indicator
path=Indicators\spread_indicator.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=4
fixed_height=-1

<graph>
name=
draw=0
style=0
width=1
arrow=251
color=
</graph>
<inputs>
font_color=13382297
font_size=10
font_face=Arial
corner=0
spread_distance_x=10
spread_distance_y=100
normalize=false
AlertIfSpreadAbove=0.0
</inputs>
</indicator>

<indicator>
name=Custom Indicator
path=Indicators\TrendVisualizer.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=4
fixed_height=-1

<graph>
name=Sth
draw=3
style=0
width=2
arrow=159
shift_y=-10
color=0
</graph>

<graph>
name=Stl
draw=3
style=0
width=2
arrow=159
shift_y=10
color=0
</graph>

<graph>
name=Ith
draw=3
style=0
width=2
arrow=159
shift_y=-10
color=42495
</graph>

<graph>
name=Itl
draw=3
style=0
width=2
arrow=159
shift_y=10
color=42495
</graph>

<graph>
name=Lth
draw=3
style=0
width=2
arrow=159
shift_y=-10
color=32768
</graph>

<graph>
name=Ltl
draw=3
style=0
width=2
arrow=159
shift_y=10
color=32768
</graph>
<inputs>
=
showLtTrend=true
showLtTrendLabel=true
showLtFractals=true
ltColor=32768
ltWidth=2
ltPointSize=2
=
showItTrend=true
showItTrendLabel=true
showItFractals=true
itColor=42495
itWidth=2
itPointSize=2
=
showStTrend=true
showStTrendLabel=true
showStFractals=true
stColor=0
stWidth=2
stPointSize=2
</inputs>
</indicator>
<object>
type=102
name=MK_PIPCOUNTER_HEADER
hidden=1
descr= 
color=42495
selectable=0
angle=0
pos_x=10
pos_y=20
fontsz=32
fontnm=Bahnschrift SemiBold
anchorpos=6
refpoint=3
</object>

<object>
name=H4 Vertical Line 2759
ray=1
date1=1734941250
</object>

<object>
type=31
name=autotrade #157660353 buy 3.87 USDCHF at 0.91691, USDCHF
hidden=1
descr=LimitBuy
color=11296515
selectable=0
date1=1736768776
value1=0.916910
</object>

<object>
type=31
name=autotrade #157706214 buy 6.89 USDCHF at 0.91678, USDCHF
hidden=1
descr=MarketBuy
color=11296515
selectable=0
date1=1736773860
value1=0.916780
</object>

<object>
type=102
name=Spread
hidden=1
descr=2 points
color=13382297
selectable=0
angle=0
pos_x=10
pos_y=100
fontsz=10
fontnm=Arial
anchorpos=0
refpoint=0
</object>

<object>
type=102
name=COUNTDOWN COLOR
hidden=1
descr=00:01:00
color=13828244
selectable=0
angle=0
pos_x=1
pos_y=1
fontsz=8
fontnm=Verdana
anchorpos=4
refpoint=2
</object>

<object>
type=102
name=Label_USDCHF
hidden=1
descr=connected
color=32768
selectable=0
angle=0
pos_x=5
pos_y=50
fontsz=10
fontnm=Arial
anchorpos=0
refpoint=1
</object>

<object>
type=102
name=TrendText_LT
hidden=1
descr=⏩
color=32768
selectable=0
angle=0
pos_x=40
pos_y=320
fontsz=20
fontnm=Arial
anchorpos=0
refpoint=3
</object>

<object>
type=102
name=TrendText_IT
hidden=1
descr=⏬
color=42495
selectable=0
angle=0
pos_x=40
pos_y=350
fontsz=20
fontnm=Arial
anchorpos=0
refpoint=3
</object>

<object>
type=102
name=TrendText_ST
hidden=1
descr=⏩
color=0
selectable=0
angle=0
pos_x=40
pos_y=380
fontsz=20
fontnm=Arial
anchorpos=0
refpoint=3
</object>

<object>
type=2
name=FractalLine_9297332_9297329
hidden=1
color=0
width=2
selectable=0
ray1=0
ray2=0
date1=1736773980
date2=1736773800
value1=0.917040
value2=0.916710
</object>

<object>
type=2
name=FractalLine_9297329_9297325
hidden=1
color=0
width=2
selectable=0
ray1=0
ray2=0
date1=1736773800
date2=1736773560
value1=0.916710
value2=0.917070
</object>

<object>
type=2
name=FractalLine_9297325_9297313
hidden=1
color=0
width=2
selectable=0
ray1=0
ray2=0
date1=1736773560
date2=1736772840
value1=0.917070
value2=0.916060
</object>

<object>
type=2
name=FractalLine_9297313_9297304
hidden=1
color=42495
width=2
selectable=0
ray1=0
ray2=0
date1=1736772840
date2=1736772300
value1=0.916060
value2=0.916640
</object>

<object>
type=2
name=FractalLine_9297304_9297298
hidden=1
color=42495
width=2
selectable=0
ray1=0
ray2=0
date1=1736772300
date2=1736771940
value1=0.916640
value2=0.916280
</object>

<object>
type=2
name=FractalLine_9297298_9297278
hidden=1
color=42495
width=2
selectable=0
ray1=0
ray2=0
date1=1736771940
date2=1736770740
value1=0.916280
value2=0.917060
</object>

<object>
type=2
name=FractalLine_9297227_9297211
hidden=1
color=32768
width=2
selectable=0
ray1=0
ray2=0
date1=1736767680
date2=1736766720
value1=0.918030
value2=0.915410
</object>

<object>
type=2
name=FractalLine_9297211_9297107
hidden=1
color=32768
width=2
selectable=0
ray1=0
ray2=0
date1=1736766720
date2=1736760480
value1=0.915410
value2=0.917780
</object>

<object>
type=2
name=FractalLine_9297107_9297030
hidden=1
color=32768
width=2
selectable=0
ray1=0
ray2=0
date1=1736760480
date2=1736755860
value1=0.917780
value2=0.916680
</object>

</window>
</chart>