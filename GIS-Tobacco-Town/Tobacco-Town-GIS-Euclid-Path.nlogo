extensions [gis table nw]
globals [
  ZONES
  ROADS
  BUILDINGS
  TRANSPORT
  SCHOOLS
  RETAILERS
  WORLD
  listzones
  listschools
  listretailers
  listhomes
  listwork
  listjobs
  listinhabitants
  wage-proportions-list
  wage-list
  smoking-proportions-list
  cigarette-list
  outlet_list
  outlet_index
  efficiency
  day
  mode
  flag
  average_costs
  end_density
]
breed [ smokers smoker ]
breed [ jobs job ]
breed [outlets outlet]
breed [nodes node]
breed [stations station]

patches-own [
  zoneid
  bldID
  bldtype
  bldSize
  sname
  school?
]

jobs-own [
  is-taken?
]
outlets-own [
  price
  PremisesNa
  BusinessTy
  difference
  current-q
  outlet_node
  best-price
  best-quantity
]
smokers-own [
  home_node
  work_node
  work
  speed
  wage
  transport_type
  hourly_wage
  discount
  inventory
  smoking_rate
  fuel_price
  distance_commute
  x_home
  y_home
  best_outlet
  day_state
  packs_purchased
  purchases_made
  total_cost_eq_per_pack
  cost_equation_per_pack
  smoker_average_overall_costs
]
links-own [
  weight
  road-name
  road-speed
  is-road?
]
nodes-own [
  node_name
  endpoint?
  line-start
  line-end
  dist-original  ;;distance from original point to here
  is-an-outlet
]
stations-own [
  service
  landmark
]

to setup
  setup-gis
  setup-zones
  setup-buildings
  setup-schools
  setup-roads
  setup-transport
  add-jobs
  add-outlets
  add-smokers
  intro-policy

  update-plots
end

to setup-gis
  CA
  reset-ticks

  gis:load-coordinate-system ("ZoneSmall.prj")
  set zones gis:load-dataset "ZoneSmall.shp"
  set roads gis:load-dataset "RoadsSmall.shp"
  set buildings gis:load-dataset "BldsSmall.shp"
  set schools gis:load-dataset "SchoolsSmall.shp"
  set retailers gis:load-dataset "tobacco.shp"
  set transport gis:load-dataset "Transport.shp"

  set world (gis:envelope-of zones)
  gis:set-transformation world (list min-pxcor max-pxcor min-pycor max-pycor)
  gis:set-world-envelope (world)                                                ;;Sets world boundary
end

to setup-zones
  set listzones table:make
  foreach  gis:feature-list-of ZONES [
    [t]->
    let c (random 75 + 25) / 100 ; a color showing walkability
    ask patches gis:intersecting t [
      let ZONE gis:property-value t "DataZone"
      set zoneid ZONE
      table:put listzones ZONE c
      set pcolor 5 + (c * 2)
    ]
  ]
end

to setup-buildings

  set listhomes table:make
  set listwork table:make
  foreach  gis:feature-list-of BUILDINGS [
    [t]->
    ask patches gis:intersecting t [
      let BTYPE gis:property-value t "type"
      let UNIT gis:property-value t "Poly_ID"
      let HEIGHT gis:property-value t "height"
      let AREA gis:property-value t "area"
      set bldID UNIT                              ;;Building ID
      set bldtype BTYPE
      set bldSize AREA * HEIGHT                   ;;Building volume
      if (bldtype = "Home") [
        set pcolor 19.9 - (bldsize / 10000)       ;; Larger buildings -> Darker colour
        table:put listhomes UNIT bldsize
      ]
      if (bldtype = "Other use") [
        set pcolor 95
        table:put listwork UNIT bldsize
      ]
    ]
  ]

end

to setup-schools

  set listschools table:make
  foreach  gis:feature-list-of SCHOOLS [
    [t]->
    ask patches gis:intersecting t [
      let NAME gis:property-value t "DISTNAME"
      table:put listschools NAME 0
      set pcolor green
      set school? true
      set sname NAME
    ]
  ]

  ; just a cleanup
  ask patches with [bldtype = "School"] [
    set pcolor green
    set school? true
    set bldID 0
    set bldtype 0
    set bldSize 0
  ]
end

to setup-roads

;; transform road from patches to networks

 foreach gis:feature-list-of ROADS [ vector-feature ->
    let first-vertex gis:property-value vector-feature "Node1"
    let last-vertex gis:property-value vector-feature "Node2"

   foreach  gis:vertex-lists-of vector-feature [ vertex ->
      let previous-node nobody

  foreach vertex [ point ->
        let location gis:location-of point
        if not empty? location
        [ create-nodes 1 [
            set xcor item 0 location
            set ycor item 1 location
            set size 0.05
            set shape "circle"
            set color one-of base-colors
            set hidden? false
            set line-start first-vertex
            set line-end last-vertex

            ifelse previous-node = nobody
              []
              [create-link-with previous-node] ; create link to previous node
               set previous-node self]
        ]
  ] ; end of foreach vertex
  ] ; end of foreach  gis:vertex-lists-of vector-feature
  ] ; end of foreach gis:feature-list-of roads

   ;;delete duplicate vertices
  ;;(there may be more than one vertice on the same patch due to reducing size of the map).
  ;;therefore, this map is simplified from the original map.
    ask nodes [
      if count nodes-here > 1 [
      ask other nodes-here  [
        ask myself [create-links-with other [link-neighbors] of myself]
        die]]
     ]

  ask links [
   set is-road? true
   set thickness 1.5
   set color yellow
    let way list [line-start] of end1 [line-end] of end2

    foreach gis:feature-list-of roads [ vector-feature-sub ->
      let vector-start gis:property-value vector-feature-sub "Node1"
      let vector-end gis:property-value vector-feature-sub "Node2"
      let start-end list vector-start vector-end
      let end-start list vector-end vector-start
      set weight gis:property-value vector-feature-sub "LnkLength" / 1000 ;; Weight = Link Length  (Divided by 1000 to convert to Miles)

      if way = start-end [set road-name gis:property-value vector-feature-sub "DescTerm"]
      if road-name = 0 or road-name = "" [set road-name [node_name] of end2 ]
      ;set max-spd read-from-string mspeed
  ]
  ]

end

to setup-transport ;; Creates public transport access points

gis:create-turtles-from-points transport stations [
    set shape "triangle"
    set size 4
    set color yellow
    ifelse member? "Station" landmark [ set service "Rail" ] [set service "Bus" ]

  ]
end

to add-outlets
  gis:create-turtles-from-points retailers outlets [
    set shape "target"
    set size 6
    set color orange
    let result 0
    set outlet_node min-one-of nodes [distance myself]

    ;; Truncated Normal Distribution for price - avoids price less than minimum
    while [result < 7.55] [ set result random-normal 7.88 0.943 ]
    if result > 7.55
    [set price result]
  ]

  ask n-of remove-outlets outlets [die] ;; Reduces outlet number for testing

  set outlet_list [self] of outlets
  set outlet_index range length outlet_list

end

to add-jobs
  set listjobs table:make
  let employment table:keys listwork
  let s (sum table:values listwork) / 2500 ; area per smoker
  foreach employment
    [
      x ->
      let area table:get listwork x
      let y ceiling (area / s)
      create-jobs y
      [
        set color red
        set size 2
        set shape "circle"
        if (count patches with [bldid = x] != 0) [move-to one-of patches with [bldid = x ]]
        set is-taken? false
      ]
  ]

        ask n-of ((count jobs) * agent-density-reduction) jobs [die] ;; Density reduction for testing
end

to add-smokers

  ;;Smoking Rate cumulative proportions

  set smoking-proportions-list [0.006 0.02 0.044 0.072 0.132 0.164 0.193 0.217 0.222 0.465 0.468 0.493 0.495 0.497 0.581 0.584 0.588 0.592 0.889 0.907 0.963 0.966 0.994 0.995 0.996 1.0]
  set cigarette-list [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 20 25 30 35 40 45 50 60]

;; Wage cumulative proportions - Data from National Income Distributions 2018

  set wage-proportions-list [.01	.04	.09	.14	.21	.28	.34	.46	.56	.64	.71	.77	.81	.88	.92	.95	1]
  set wage-list [100 150 200 250 300 250 400 500 600 700 800 900 1000 1200 1400 1600 2000]

  ;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;

  set listinhabitants table:make
  let homes table:keys listhomes
  let s (sum table:values listhomes) / 2500 ; area per smoker
  foreach homes
    [
      x ->
      let area table:get listhomes x
      let y ceiling (area / s )
      create-smokers y
      [
        set color blue
        set size 2
        set shape "circle"
        if (count patches with [bldid = x] != 0) [move-to one-of patches with [bldid = x ]]

    ]
  ]
        ask n-of ((count smokers) * agent-density-reduction) smokers [die] ;; Reduces density for testing purposes

  ask smokers[

     let rand random-float 1.0
    set transport_type (ifelse-value        ;; Set Transport Type: Real Data DataShine Scotland Commute
        rand < 0.43 [ "walk" ]
        rand < 0.68 ["train"]
        rand < 0.88 [ "car" ]
        rand < 0.94 [ "bus" ]
        rand < 1 ["bike"]
        [ "home" ]
        )
    if transport_type = "home" [ die ]      ;; Tobacco Town paper does not model those that work from home
                                            ;; Proportions do not add up to 1

    (ifelse
        transport_type = "car" [set speed 19.9] ;; Set movement speed
        transport_type = "walk" [set speed 2.1]
        transport_type = "bike" [set speed 7.5]
        transport_type = "bus" [set speed 7.5]  ;;Placeholder
        transport_type = "train" [set speed 18] ;;placeholder
        )

    if transport_type != "train" and transport_type != "bus" [
        set work one-of jobs with [ is-taken? = false ] ;; Assigns Job
        ask work [ set is-taken? true ]
    ]

    if transport_type = "train" [
      set work min-one-of stations with [service = "Rail"] [distance myself]
    ]

   if transport_type = "bus" [
      set work min-one-of stations with [service = "Bus"] [distance myself]
    ]

   if work = nobody [die]    ;; Ensures all smokers have a job

 ;; Smoking rate cumulative proportions

    let random-number-smoke random-float 1.0
    let index-smoke 0
    while [index-smoke < length smoking-proportions-list - 1 and random-number-smoke > item index-smoke smoking-proportions-list] [set index-smoke index-smoke + 1]
    let cigarettes item index-smoke cigarette-list
    set smoking_rate cigarettes

;; Wage Cumulative Proportions

    let random-number-wage random-float 1.0
    let index-wage 0
    while [index-wage < length wage-proportions-list - 1 and random-number-wage > item index-wage wage-proportions-list] [set index-wage index-wage + 1]
    set wage item index-wage wage-list
    set hourly_wage ( wage / 40 )


    set home_node min-one-of nodes [distance myself]
    set work_node work-node                                      ;; Reported procedure (work-node) below
    set distance_commute get-commute
    set inventory random 40
    set discount (ifelse-value                                   ;; A discount rate that devalues packs purchased in the future
          smoking_rate <= 10 [ ( 0.935 + random-float 0.065 ) ]
          smoking_rate < 20 and smoking_rate > 10 [ (0.9 + random-float 0.1) ]
          smoking_rate = 20 [ (0.88 + random-float 0.12 ) ]
          smoking_rate > 20 [ (0.815 + random-float 0.185 ) ])
    set-fuel-price
    set total_cost_eq_per_pack []
    set efficiency 21 ;; Placeholder
    set mode "all_at_home"
    set day 0
  ]

end

to-report work-node
  let w_n 0
  ask work [ set w_n min-one-of nodes [distance myself]]
  report w_n
end

to-report get-commute
  let com 0
  let w_n work_node
  ask home_node [ set com nw:weighted-distance-to w_n weight] ;; Weighted distance used - to factor for road length
  report com
end

to set-fuel-price
  ask smokers [
    (ifelse
      transport_type = "car"
      [set fuel_price 6.02] ;;Fuel price for 2018 (£/Gallon)
      [set fuel_price 0 ]
      )
  ]
end

to intro-policy

;;;;;;;;;;;;;;;;;;;;;;;;;;; Density Cap

let outlet-reduction-factor (1 - (retailer-density-cap * 0.01 ))

if retailer-density-cap != 100 [
 ask n-of (count outlets * outlet-reduction-factor) outlets [
      ask outlet_node [ set is-an-outlet 0]
      die
      ]
  ]

;;;;;;;;;;;;;;;;;;;;;;;; School buffer

let school-buffer-factor (ifelse-value
    school-buffer = "None" [ 0 ]
    school-buffer = "500 Ft" [ 50 ] ;; Each patch represents 10 feet
    school-buffer = "1000 Ft" [ 100 ]
    school-buffer = "1500 Ft" [ 150 ]
    )
if school-buffer != "None" [
  ask outlets [
      ask outlets [if any? patches in-radius school-buffer-factor with [school? = true ] [die]]
    ]
  ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;; Retailer Minimum Distance

  let retailer-buffer-factor (ifelse-value
    retailer-distance-buffer = "None" [ 0 ]
    retailer-distance-buffer = "500 Ft" [ 50 ]
    retailer-distance-buffer = "1000 Ft" [ 100 ]
    retailer-distance-buffer = "1500 Ft" [ 150 ]
    )

if retailer-distance-buffer != "None" [
    ask outlets [
    if any? other outlets in-radius retailer-buffer-factor [
      ask outlet_node [ set is-an-outlet 0]
      die
     ]
   ]
 ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Retailer Removal

ask outlets
  [ if businessty = retailer-type-removal [
    ask outlet_node [ set is-an-outlet 0 ]
    die
    ]
  ]


  set outlet_list [self] of outlets
  set outlet_index range length outlet_list  ;; create index of that ordered list
end


to go

  if day = number-of-days [
  report-end-state
  stop]

    ask smokers [ifelse inventory < smoking_rate [purchase] [commute] ]
    ask smokers [ set inventory ( inventory - smoking_rate ) ]
    set day (day + 1)
end

to commute
;; So far do nothing
end

to purchase
  find-retailer
  get-costs

  set inventory ( inventory + ( packs_purchased * 20) )
  set purchases_made ( purchases_made + 1 )
  set total_cost_eq_per_pack lput cost_equation_per_pack total_cost_eq_per_pack
  print best_outlet
  print word "$" cost_equation_per_pack
end

to find-retailer

  let s_list []
  calc-price
    set s_list sort-by [ [?1 ?2 ] -> get-best-price  ?1  < get-best-price  ?2  ] outlet_index

  let index_no 0


    ;;; TREMBLING HAND - acts as a weighted roulette wheel

    let prob-not-best 0.97
    ifelse random-float 1 > prob-not-best [
      set index_no item 0 s_list
    ][
      let c 1
      let p random-float 1

      let calc  0.5 ^ ( c - 1 ) * 0.5

      while [ calc < p and c < length s_list - 1 ]
        [
          set c c + 1
          set calc calc + ( 0.5 ^ ( c - 1 ) * 0.5 )
        ]

      set index_no item c s_list
    ]
    set best_outlet item index_no outlet_list


end

to calc-price
  let cost-at-r 0
  let calc 0
  let c_distance_commute distance_commute
  let c_work_node work_node
  let c_home_node home_node
  let c_x_work 0
  let c_y_work 0
  let c_discount discount
  let c_speed speed
  let c_hourly_wage hourly_wage
  let c_inventory inventory
  let c_smoking_rate smoking_rate
  let c_transport_type transport_type
  let c_fuel_price fuel_price

ask outlets[
    let home_out_work 0
    ask outlet_node [ set home_out_work ( ( nw:weighted-distance-to c_home_node weight ) + ( nw:weighted-distance-to c_work_node weight ) ) ]
    set difference home_out_work - c_distance_commute
    let quantity 1
    set current-q quantity

 let min-value 9999
  ;; Start at 1 pack and increases q each iteration
  repeat 100 [
      let c_price price
      if quantity mod 10 = 0 and buy-cartons? = true [ set c_price ( ( price * 7.63 ) / 10 ) ]

    let qq-list n-values quantity [x -> x + 1]
    ;; Generates a list of values from 1 to q eg [ 1 2 3 4 5 6] for q=6

  let sum-function sum (map [ x -> c_discount ^ floor ((20 * (x - 1) + c_inventory) / c_smoking_rate) ] qq-list)
    ;; Separates complicated sum function from main equation

    let current-value (  ((( difference / c_speed + 1 / 12) * c_hourly_wage * 1 + difference * c_fuel_price / efficiency + quantity * c_price ) / sum-function ))
      ;; Cost Calculation

    if current-value < min-value [
      set min-value current-value
      set calc current-value
      set current-q quantity
      set cost-at-r   (( difference / c_speed + 1 / 12) * c_hourly_wage * 1 + difference * c_fuel_price / efficiency + current-q * c_price ) / current-q
        ]
      ;; If newest value is lower, min-value is updated and current-q is recorded

    set quantity quantity + 1
    ;; Begins calculation for next value of q

  ]
  set best-price cost-at-r
  set best-quantity current-q
  ]

end

to-report get-best-price [ index]
  let cost-at-r 0
  ask  item index outlet_list [
    set  cost-at-r best-price
  ]
 report cost-at-r
end

to get-costs

;;;;;;;;;;;;;;;;;;;;;;;;Updates all purchase-related variables

      let pack-price [price] of best_outlet
      ;set retailer-type [outlet-type] of best_outlet
      let distance-for-purchase [difference] of best_outlet
      set packs_purchased [current-q] of best_outlet
      if packs_purchased mod 10 = 0 [ set pack-price ( (pack-price * 7.63 ) / 10 ) ]
      ;set cost-for-purchase ( packs-purchased * pack-price )
      ;set cost-for-travel ( [difference] of best_outlet * fuel-price / efficiency )
      ;set time-for-purchase ( [difference] of best_outlet / speed )
      ;set total-per-pack-cost ( cost-for-travel + cost-for-purchase ) / packs-purchased

  set cost_equation_per_pack [best-price] of best_outlet

  print word "Packs:" packs_purchased
  print word "Cost: $" cost_equation_per_pack

end

to report-end-state

  ask smokers [

    if purchases_made != 0
    [set smoker_average_overall_costs ( ( sum total_cost_eq_per_pack) / purchases_made )
     ;set smoker-average-purchase-cost ( ( sum total-cost-for-purchase ) / purchases-made )
     ;set smoker-average-travel-cost (( sum total-cost-for-travel ) / purchases-made )
     ;set smoker-average-distance (( sum total-distance-travelled) / purchases-made )
     ;set smoker-average-purchase-quantity (( sum total-purchase-quantity ) / purchases-made )
   ]
  ]
  set average_costs ( mean [ smoker_average_overall_costs ] of smokers)

  ;set average-purchase-costs ( mean [smoker-average-purchase-cost ] of smokers )
  ;set average-travel-costs ( mean [smoker-average-travel-cost ] of smokers )
  ;set average-distance ( mean [ smoker-average-distance] of smokers )
  ;set average-purchase-quantity ( mean [ smoker-average-purchase-quantity ] of smokers )

  set end_density ( count outlets ) / (world-height * world-width * 3.58701e-6 ) ;; Conversion from sqaure 10ft to square miles
end
@#$#@#$#@
GRAPHICS-WINDOW
191
10
1059
714
-1
-1
1.49142
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
576
0
465
0
0
1
ticks
30.0

BUTTON
28
136
92
169
Setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
100
136
163
169
Go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SWITCH
5
62
186
95
buy-cartons?
buy-cartons?
1
1
-1000

SLIDER
5
28
186
61
number-of-days
number-of-days
1
30
20.0
1
1
NIL
HORIZONTAL

MONITOR
1063
569
1135
614
NIL
mode
17
1
11

MONITOR
1140
569
1191
614
NIL
day
17
1
11

SLIDER
5
97
187
130
remove-outlets
remove-outlets
0
26
0.0
1
1
NIL
HORIZONTAL

TEXTBOX
8
10
158
35
SETUP
15
0.0
1

PLOT
4
173
187
294
Smoking Rate
Smoking Rate (/day)
Count
0.0
60.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [smoking_rate] of smokers"

PLOT
3
295
187
416
Income Disribution
Weekly Income (£)
Count
0.0
2000.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [wage] of smokers"

TEXTBOX
5
423
172
449
POLICY
15
0.0
1

SLIDER
4
444
179
477
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
4
480
179
525
school-buffer
school-buffer
"None" "1500 Ft" "1000 Ft" "500 Ft"
0

CHOOSER
4
529
179
574
retailer-distance-buffer
retailer-distance-buffer
"None" "1500 Ft" "1000 Ft" "500 Ft"
0

CHOOSER
4
578
179
623
retailer-type-removal
retailer-type-removal
"None" "Convenience Store"
0

BUTTON
4
626
124
659
Introduce Policy
Intro-policy
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1063
550
1213
648
Each patch = 10ft
11
0.0
1

MONITOR
1063
669
1259
714
Total Average Cost (per pack)(£)
average_costs
2
1
11

MONITOR
1063
621
1260
666
Retailer Density (per square mile)
( count outlets ) / (world-height * world-width * 3.58701e-6 )
2
1
11

SLIDER
1066
144
1254
177
agent-density-reduction
agent-density-reduction
0
0.99
0.5
0.01
1
NIL
HORIZONTAL

TEXTBOX
1071
184
1221
202
for testing
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
  <experiment name="experiment" repetitions="3" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>average_costs</metric>
    <metric>end_density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-density-reduction">
      <value value="0.92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="buy-cartons?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="remove-outlets">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-type-removal">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-distance-buffer">
      <value value="&quot;None&quot;"/>
      <value value="&quot;None&quot;"/>
      <value value="&quot;500 Ft&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-density-cap">
      <value value="100"/>
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
