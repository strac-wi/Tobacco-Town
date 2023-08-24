extensions [ nw ]
undirected-link-breed [ node-links node-link ]

breed [ nodes node ]
breed [ workplaces workplace ]
breed [ schools school ]
breed [ outlets outlet ]
breed [ smokers smoker ]

globals [
  population-density
  school-density
  workplace-density
  efficiency
  vl
  wage-proportions-list
  wage-list
  smoking-proportions-list
  cigarette-list
  outlet_list
  outlet_index  ;; a list of indexes to the outlets
  mode ;; what time of day is it?  "go_to_work" "go_home" "all_at_home"
  flag ;; are agents moving;
  day
  average-costs
  average-purchase-costs
  average-travel-costs
  average-distance
  average-purchase-quantity
  end-density
]
turtles-own [ is-a-node ]
smokers-own [
  work
  smokers_home
  home_work
  commute_nodes
  journey
  day_state
  s_color
  journey_length
  transport-type
  speed
  wage
  hourly-wage
  discount
  inventory
  smoking-rate
  fuel-price
  nearest_outlet
  pack-price
  packs-purchased
  cost-for-purchase
  cost-for-travel
  distance-for-purchase
  time-for-purchase
  smoker-average-overall-costs
  smoker-average-purchase-cost
  smoker-average-travel-cost
  smoker-average-distance
  smoker-average-purchase-quantity
  total-distance-travelled
  total-cost-for-purchase
  total-cost-for-travel
  total-time-for-purchase
  total-per-pack-cost
  total-cost-eq-per-pack
  total-purchase-quantity
  retailer-type
  list-retailer-type
  purchases-made
  cost-equation
  cost-equation-per-pack

]
nodes-own [
  place
  is-an-outlet
  is-a-workplace
  is-a-school
  is-a-home
]
outlets-own [
  outlet_place
  price
  outlet-type
  difference
  current-q
  best-price
  best-quantity
]
workplaces-own [
place
]



to setup
clear-all
;; Set population-density --> allows manual setting of population density if switch set to "ON"

  (ifelse
     town-type = "Urban Poor" [ set population-density 19 ]
     town-type = "Urban Rich" [ set population-density 240 ]
  )

;; Set workplace-density
  (ifelse
    town-type = "Urban Poor" [ set workplace-density 72.81 ]
    town-type = "Urban Rich" [ set workplace-density 215 ] ;;GIS
    )
 ;; Set School density
    (ifelse
    town-type = "Urban Poor" [ set school-density 2.82 ]
    town-type = "Urban Rich" [ set school-density 6 ] ;;GIS
    )

  set efficiency 33 ;; UK Department of Transport
  set vl 1 ;; Linear value of time parameter - set to 1 for all agents


  generate-env
  generate-workplaces
  generate-schools

  if town-type = "Urban Poor" [
    let wage-proportions [0.014	0.057	0.125	0.206	0.29	0.37	0.444	0.571	0.665	0.74	0.798	0.843	0.878	0.926	0.954	0.971	0.989 1 ]
    generate-smokers  wage-proportions 0.8797 0.892 0.9817
    generate-outlet-type  "Retailer" orange 16.6 8.63 0.943 7.77
  ]


  ;; Urban rich is matched to GIS
  if town-type = "Urban Rich" [
    let wage-proportions  [0.01	0.05	0.10	0.17	0.23	0.30	0.36	0.48	0.57	0.65	0.71	0.76	0.81	0.87	0.92	0.95	0.98 1]
    generate-smokers  wage-proportions 1 0.43 0.8
    generate-outlet-type  "Retailer" orange 42.51 7.88 0.943 7.55
  ]

  set-fuel-price
  density-reduction

  set outlet_list [self] of outlets          ;; outlet_list is a list structure but its order is random
  set outlet_index range length outlet_list  ;; create index of that ordered list

  set mode "all_at_home"
  set day 0
  update-plots

end


to generate-env

 nw:generate-lattice-2d turtles links world-width world-height false
 (foreach (sort turtles) (sort patches) [ [t p] -> ask t [ move-to p ] ])

;; creates lattice of nodes equal to world size

ask patches [set pcolor 7]


  ask turtles [
    set breed nodes
    set shape "circle"
    set color white
    set size 0
    set place "none"
    set is-a-node 1
  ]

  ask links [set color 0 set thickness 0.1 ]

end

to generate-workplaces

  if workplace-density > ( (count nodes) / ( world-width * world-height / 1000 ) ) [ set workplace-density ( (count nodes) / ( world-width * world-height / 1000 ) ) ]

  ;;If workplace density is grteater than number of nodes then limits density to this (for Urban Rich)

  create-workplaces ( round ( (world-width * world-height / 1000 ) * workplace-density )) [
    move-to one-of nodes with [ is-a-workplace = 0 ]
    ask nodes-here [ set is-a-workplace 1 ]
    set color blue
    set shape "box"
    set size 0.4

    ]

end

to generate-smokers [t-wage-proportions car-proportion walk-proportion bike-proportion ]

;;Smoking Rate cumulative proportions - for all town types from SHS 2021 Smoking Module (UK Data Service)

  set smoking-proportions-list [0.037 0.066 0.125 0.160 0.253 0.304 0.328 0.365 0.370 0.578 0.639 0.647 0.655 0.807 0.810 0.818 0.957 0.968 0.989 1.000]
  set cigarette-list [1 2 3 4 5 6 7 8 9 10 12 13 14 15 17 18 20 25 30 40]

;; Wage cumulative proportions

  set wage-proportions-list t-wage-proportions
  set wage-list [100 150 200 250 300 250 400 500 600 700 800 900 1000 1200 1400 1600 2000 2500] ;; Wage Data Can come from GIS once areas are decided

  create-smokers (round ( population-density * ( world-width * world-height / 1000 ))) [

      ;; Transport Type
    let rand random-float 1.0
    set transport-type (ifelse-value
        rand < walk-proportion [ "walk" ]
        rand < bike-proportion [ "bike" ]
        rand < car-proportion [ "car" ]
        [ "home" ]
        )
    if transport-type = "home" [ die ] ;; Tobacco Town paper does not model those that work from home
                                       ;; Hence proportions do not add up to 1

    (ifelse
        transport-type = "car" [set speed 19.9]
        transport-type = "walk" [set speed 2.1]
        transport-type = "bike" [set speed 7.5]
        )

;; Wage Cumulative Proportions
    let random-number-wage random-float 1.0
    let index-wage 0
    while [index-wage < length wage-proportions-list - 1 and random-number-wage > item index-wage wage-proportions-list] [set index-wage index-wage + 1]
    set wage item index-wage wage-list

    set hourly-wage (wage / 40 ) ;; Divide weekly income

;; Smoking rate cumulative proportions
    let random-number-smoke random-float 1.0
    let index-smoke 0
    while [index-smoke < length smoking-proportions-list - 1 and random-number-smoke > item index-smoke smoking-proportions-list] [set index-smoke index-smoke + 1]
    let cigarettes item index-smoke cigarette-list
    set smoking-rate cigarettes

;; Discount term devalues cigarettes purchased in the future
      set discount (0.54 + random-float 0.46)

    let x_work 0
    let y_work 0
    set color white
    set shape "person"
    set size 0.6
    set inventory random 40
    set smokers_home one-of nodes

    ask smokers_home [

      set color 36
      set shape "house"
      set size 0.5
      set is-a-home 1

    ]
    move-to smokers_home
    set work one-of nodes with [ is-a-workplace = 1 and distance myself > 0 ]

    let s_work work
    let home_work_nodes 0
    ask smokers_home [
      set home_work_nodes nw:turtles-on-path-to s_work
    ]

    set commute_nodes turtle-set home_work_nodes      ;; Stores nodes on smokers commute
  ]

;;initialise lists for recording individual purchases
  ask smokers [
  set total-distance-travelled []
  set total-cost-for-purchase []
  set total-cost-for-travel []
  set total-time-for-purchase []
  set total-cost-eq-per-pack []
  set list-retailer-type []
  set total-purchase-quantity []
  ]


end

to generate-outlet-type [ t-name t-color t-prop  t-dist-l t-dist-m t-dist-r  ]
    create-outlets ( round ( (world-width * world-height / 1000 ) * random-normal t-prop 0.5 )) [
    set outlet-type t-name
    set color t-color
    set shape "target"
    set size 0.4
    set price price-normal-dist t-dist-l t-dist-m t-dist-r
    set outlet_place one-of nodes with [ is-an-outlet = 0 ]
    ask outlet_place [
      set is-an-outlet 1
    ]
    move-to outlet_place
  ]

end

to generate-schools

    create-schools ( school-density * (world-height * world-width / 1000 ) ) [
    set color 55
    set shape "tree"
    set size 0.4
    move-to one-of nodes
  ]
end

to-report price-normal-dist [mid dev mmin]   ;; generates a retailer specific pack price from a truncated normal distribution
  let result random-normal mid dev
  if result < mmin
    [ report price-normal-dist mid dev mmin ]
  report result
end

to set-fuel-price
  ask smokers [
    (ifelse
      transport-type = "car"
      [set fuel-price 5.92 ] ;; UK Fuel prices per gallon 2018
      [set fuel-price 0 ]
      )
  ]
end

to run-fast
  if day = number-of-days [
    report-end-state
    print timer
    stop
  ]
  ask smokers [
    set inventory ( inventory - smoking-rate )
    if inventory < smoking-rate [
      purchase
    ]
  ]
  set day (day + 1)
end

to purchase
  set color red
  find-optimum-path
  get-costs

  ;;Update all purchase related variables and lists
  set inventory ( inventory + ( packs-purchased * 20) )
  set purchases-made ( purchases-made + 1 )

  set total-distance-travelled lput distance-for-purchase total-distance-travelled
  set total-cost-for-purchase lput cost-for-purchase total-cost-for-purchase
  set total-cost-for-travel lput cost-for-travel total-cost-for-travel
  set total-time-for-purchase lput time-for-purchase total-time-for-purchase
  set total-cost-eq-per-pack lput cost-equation-per-pack total-cost-eq-per-pack
  set total-purchase-quantity lput packs-purchased total-purchase-quantity
  set list-retailer-type lput retailer-type list-retailer-type
end

to find-optimum-path
  ;; this will find the outlet that is best on way to work

  let s_list []
  calc-price
    set s_list sort-by [ [?1 ?2 ] -> get-best-price  ?1  < get-best-price  ?2  ] outlet_index

;; Trembling hand - there is a probability of 0.025 that the optimum retailer is not chosen (procedure below)
  let index_no 0
  ifelse random-float 1 > 0.025 [ ;; 0.025 = Probability that the best retailer isn't chosen

      set index_no item 0  s_list
    ][

      let c 1
      let p random-float 1
      let calc  0.5 ^ ( c - 1 ) * 0.5

      while [ calc < p and c < length s_list - 1 ]
        [
          set c c + 1
          set calc calc + ( 0.5 ^ ( c - 1 ) * 0.5 )
        ]

      set index_no item c  s_list
    ]

    set nearest_outlet  item index_no outlet_list

    set day_state "to_work"

end

to-report get-best-price [ index]
  let cost-at-r 0
  ask  item index outlet_list [
    set  cost-at-r best-price
  ]
 report cost-at-r
end

to calc-price
  let cost-at-r 0
  let calc 0
  let s_commute_nodes commute_nodes
  let c_discount discount
  let c_speed speed
  let c_hourly-wage hourly-wage
  let c_inventory inventory
  let c_smoking-rate smoking-rate
  let c_transport-type transport-type
  let c_fuel-price fuel-price


  ask  outlets [
    let nearest-node min-one-of s_commute_nodes [ distance myself ]
    let off_path 0
    ask outlet_place [
    set off_path nw:distance-to nearest-node
    ]

    set difference (off_path / 15)

    let quantity 1
    set current-q quantity
    let min-value 99999
    ;; Start at 1 pack and increase q each iteration
    repeat 100 [
      let c_price price

      let qq-list n-values quantity [x -> x + 1]
      ;; Generates a list of values from 1 to q eg [ 1 2 3 4 5 6] for q=6

      let sum-function sum (map [ x -> c_discount ^ floor ((20 * (x - 1) + c_inventory) / c_smoking-rate) ] qq-list)
      ;; Separates complicated sum function from main equation

      let current-value (  ((( difference / c_speed + 1 / 12) * c_hourly-wage * vl + difference * c_fuel-price / efficiency + quantity * c_price ) / sum-function ))
      ;; Calculation

      if current-value < min-value [
        set min-value current-value
        set current-q quantity
        set cost-at-r   (( difference / c_speed + 1 / 12) * c_hourly-wage * vl + difference * c_fuel-price / efficiency + current-q * c_price ) / current-q
        ;; If newest value is lower, min-value is updated and current-q is recorded
      ]

      set quantity quantity + 1
      ;; Beginds calculation for next value of q

    ] ;; 100 loop

    set best-price cost-at-r
    set best-quantity current-q
  ] ;; outlets loop


end

to get-costs
  set pack-price [price] of nearest_outlet
  set retailer-type [outlet-type] of nearest_outlet
  set distance-for-purchase [difference] of nearest_outlet
  set packs-purchased [best-quantity] of nearest_outlet
  set cost-for-purchase ( packs-purchased * pack-price )
  set cost-for-travel ( [difference] of nearest_outlet * fuel-price / efficiency )
  set time-for-purchase ( [difference] of nearest_outlet / speed )
  set total-per-pack-cost ( cost-for-travel + cost-for-purchase ) / packs-purchased
  set cost-equation-per-pack [best-price] of nearest_outlet
end

to density-reduction

  ;; Density Cap

let outlet-reduction-factor (1 - (retailer-density-cap * 0.01 ))

if retailer-density-cap != 100 [
 ask n-of (count outlets * outlet-reduction-factor) outlets [
      ask outlet_place [ set is-an-outlet 0]
      die
      ]
  ]

  ;; School buffer

let school-buffer-factor (ifelse-value
    school-buffer = "None" [ 0 ]
    school-buffer = "500 Feet" [ 1 ]
    school-buffer = "1000 Feet" [ 2 ]
    school-buffer = "1500 Feet" [ 3 ]
    )
if school-buffer != "None" [
  ask schools [
    ask outlets [ if distance myself <= school-buffer-factor [
      ask outlet_place [ set is-an-outlet 0]
      die
      ]
  ]
 ]
]

  ;; Retailer Minimum Distance

  let retailer-buffer-factor (ifelse-value
    retailer-min-distance-buffer = "None" [ 0 ]
    retailer-min-distance-buffer = "500 Feet" [ 1 ]
    retailer-min-distance-buffer = "1000 Feet" [ 2 ]
    retailer-min-distance-buffer = "1500 Feet" [ 3 ]
    )
if retailer-min-distance-buffer != "None" [
  ask outlets [
    if any? other outlets in-radius retailer-buffer-factor [
      ask outlet_place [ set is-an-outlet 0]
      die
      ]
  ]
 ]

ask outlets ;; Retailer removal can't be done in this environment
  [ if outlet-type = retailer-removal [
    ask outlet_place [ set is-an-outlet 0 ]
    die
    ]
  ]
  set outlet_list [self] of outlets
  set outlet_index range length outlet_list  ;; create index of that ordered list


end

to report-end-state

  ask smokers [

    if purchases-made != 0
    [set smoker-average-overall-costs ( ( sum total-cost-eq-per-pack) / purchases-made )
     set smoker-average-purchase-cost ( ( sum total-cost-for-purchase ) / purchases-made )
     set smoker-average-travel-cost (( sum total-cost-for-travel ) / purchases-made )
     set smoker-average-distance (( sum total-distance-travelled) / purchases-made )
     set smoker-average-purchase-quantity (( sum total-purchase-quantity ) / purchases-made )
   ]
  ]
  set average-costs ( mean [ smoker-average-overall-costs ] of smokers)

  set average-purchase-costs ( mean [smoker-average-purchase-cost ] of smokers )
  set average-travel-costs ( mean [smoker-average-travel-cost ] of smokers )
  set average-distance ( mean [ smoker-average-distance] of smokers )
  set average-purchase-quantity ( mean [ smoker-average-purchase-quantity ] of smokers )

  set end-density  ( count outlets ) / (world-height * world-width / 100)


end
@#$#@#$#@
GRAPHICS-WINDOW
223
20
562
360
-1
-1
10.344
1
10
1
1
1
0
0
0
1
0
31
0
31
0
0
1
ticks
30.0

BUTTON
10
122
77
155
SETUP
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
7
33
203
78
town-type
town-type
"Urban Poor" "Urban Rich"
1

MONITOR
772
10
889
55
Population Density
count smokers / ((world-height * world-width) / 1000 )
1
1
11

PLOT
776
267
976
417
Smoking Rate Distribution
Smoking Rate (per day)
Count
0.0
60.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [smoking-rate] of smokers"

PLOT
774
107
974
257
Wage Distribution
Wage ($)
Count
0.0
2500.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [wage] of smokers"

MONITOR
773
58
889
103
Total Retailer Density
count outlets / (world-height * world-width / 1000)
1
1
11

MONITOR
892
10
1008
55
School Density
count schools / (world-width * world-height / 1000 )
1
1
11

MONITOR
413
367
498
412
NIL
mode
17
1
11

BUTTON
84
122
147
155
GO
run-fast
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
564
41
736
74
retailer-density-cap
retailer-density-cap
50
100
100.0
10
1
%
HORIZONTAL

CHOOSER
565
78
736
123
school-buffer
school-buffer
"None" "500 Feet" "1000 Feet" "1500 Feet"
0

CHOOSER
566
127
736
172
retailer-min-distance-buffer
retailer-min-distance-buffer
"None" "500 Feet" "1000 Feet" "1500 Feet"
0

CHOOSER
566
177
737
222
retailer-removal
retailer-removal
"None" "Pharmacies" "Convenience"
0

BUTTON
566
226
693
259
Introduce Policy
density-reduction\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
506
366
563
411
NIL
day
17
1
11

SLIDER
7
83
204
116
number-of-days
number-of-days
1
30
30.0
1
1
days
HORIZONTAL

MONITOR
893
58
1009
103
Area (square miles)
(world-height * world-width ) / 1000
17
1
11

TEXTBOX
17
11
167
31
SETUP
16
0.0
0

TEXTBOX
572
16
722
36
POLICY TESTING
16
0.0
0

MONITOR
210
369
379
414
Average Total Cost Per Pack ($)
average-costs
2
1
11

BUTTON
77
173
154
206
NIL
run-fast\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## PATHFINDING 

Model uses distance off commute to retailer:

 - Nearest commute node to retailer is selected as starting point 

 - nw:distance-to retailer to calculate distance off route

## VARIABLES

- Wage (CORRECT) from banded household income data 2018
- Smoking-rate (CORRECT) from Scottish Health Survey 2021 - smoking module
- Retailer density (CORRECT) Kernal density estimation data 
- School density (CORRECT) School catchments open data 2021
- Workplace density (CORRECT) From LuminoCity Employment density
- Population density (CORRECT) SIMD Data 2020
- Fuel Price **£5.92 / gallon** (CORRECT) Weekly fuel prices 17/09/18 
- Transport Type (CORRECT) 2011 Scottish Census 
- Speed (CORRECT) TomTom 2018 (car) Allen et al (bike) Knoblauch et al (walk)


UNSURE:

* Discount/devaluing rate (POTENTIALLY INCORRECT) Taken from Tobacco Town 
* Tobacco Price (POTENTIALLY INCORRECT) Taken from 2 and 5 deprivation scaled mean price    paid for cigarettes regardless of brand. Using point-of-sale data to examine tobacco pricing across neighbourhoods in Scotland 2021
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Baseline" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-min-distance-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-density-cap">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Retailer Density Cap" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-min-distance-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-density-cap">
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="School Distance Buffer" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school-buffer">
      <value value="&quot;1500 Feet&quot;"/>
      <value value="&quot;1000 Feet&quot;"/>
      <value value="&quot;500 Feet&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-min-distance-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-density-cap">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Retailer Distance Buffer" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-min-distance-buffer">
      <value value="&quot;1500 Feet&quot;"/>
      <value value="&quot;1000 Feet&quot;"/>
      <value value="&quot;500 Feet&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-density-cap">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="High Strength Combination" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school-buffer">
      <value value="&quot;1500 Feet&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-min-distance-buffer">
      <value value="&quot;1500 Feet&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-density-cap">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Moderate Strength Combination" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school-buffer">
      <value value="&quot;1000 Feet&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-min-distance-buffer">
      <value value="&quot;1000 Feet&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-density-cap">
      <value value="75"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
