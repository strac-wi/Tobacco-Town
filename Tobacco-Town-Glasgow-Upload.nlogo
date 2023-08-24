extensions [ nw ]

breed [ nodes node ]
breed [ workplaces workplace ]
breed [ schools school ]
breed [ outlets outlet ]
breed [ smokers smoker ]
undirected-link-breed [ node-links node-link ]

globals [
  population-density       ;; Census data for each area - scaled by 0.01
  school-density
  workplace-density
  efficiency               ;; Vehicle efficiency (MPG)
  vl                       ;; Linear value of time parameter - set to 1 for all agents
  wage-proportions-list    ;; List of cumulative proportions for each wage catagory
  wage-list                ;; List of wage catagories
  smoking-proportions-list ;; List of cumulative proportions for each smoking rate catagory
  cigarette-list           ;; List of smoking rates
  outlet-list              ;; List of outlets
  outlet-index             ;; a list of indexes to the outlets
  mode                     ;; Time of day  "go_to_work" "go_home" "all_at_home"
  flag                     ;; Set to 1 if agents are moving
  day
  average-costs            ;; Aggregate TPC (total pack cost) the combined travel and purchase cost per pack (£)
  end-density              ;; Retailer density
]
turtles-own [ is-a-node ]
smokers-own [
  work                     ;; Work location
  smokers-home             ;; Home location
  commute-nodes            ;; List of nodes on commute (agent-set)
  commute-path             ;; List of nodes on commute (path)
  journey                  ;; Smokers current journey
  day-state                ;; What smoker is doing "to_work" or "to_home"
  journey-length           ;; Length of current journey
  transport-type           ;; Car / Bike / Walk
  speed                    ;; Travel speed - dependant on transport-type
  wage                     ;; Weekly income - genereated from wage-proportions and wage-list
  hourly-wage
  discount                 ;; Discount term devalues cigarettes purchased in the future (calculation) - Uniform distribution
  inventory                ;; Cigarette inventory
  smoking-rate
  fuel-price               ;; Fuel price £/Gallon
  selected-outlet          ;; The retailer selected for purchase
  pack-price               ;; The pack-price at the selected retailer
  packs-purchased          ;; Quantity of packs purchased (stored per purchase)
  smoker-average-costs     ;; Average TPC per smoker
  total-cost-per-pack      ;; Combined TPC for every purchase
  purchases-made           ;; Number of transactions
  total-pack-cost          ;; TPC (£) the combined travel and purchase cost for one pack
]

nodes-own [
  is-an-outlet
  is-a-workplace
  is-a-school
  is-a-home
]

outlets-own [
  outlet-place            ;; The node the retailer is on
  price                   ;; Pack price at retailer
  outlet-type             ;; Type - not included in this model
  nearest-node            ;; The commute node that is closest to the retailer - updates every smoker purchase
  difference              ;; The distance off route - updates every smoker purchase
  current-q               ;; The current optimum quantity - Optimisation calculation
  best-tpc                ;; The TPC of purchasing the optimum quantity at the selected retailer
  best-quantity           ;; The optimum purchase quantity at the selected retailer
]

to reset-model ;; Resets entire model - for start of experiment
  clear-turtles
  clear-links
  clear-globals
  clear-patches
  clear-plot

  set retailer-density-cap 100
  setup
end

to setup

 clear-turtles
 clear-links
 clear-globals
 clear-patches
 clear-drawing

 set wage-list [100 150 200 250 300 350 400 500 600 700 800 900 1000 1200 1400 1600 2000 2500]                                     ;; Wage cumulative proportions - Wage list and proportions list from Household Income 2018

 set smoking-proportions-list [.037 .066 .125 .160 .253 .304 .328 .365 .370 .578 .639 .647 .655 .807 .810 .818 .957 .968 .989 1]   ;;Smoking rate cumulative proportions - same for both areas
 set cigarette-list [1 2 3 4 5 6 7 8 9 10 12 13 14 15 17 18 20 25 30 40]                                                           ;;Smoking rate list - from SHS 2021 Smoking Module (UK Data Service)

;; Set population-density

   (ifelse
     town-type = "Urban Poor" [ set population-density 95.04 ]                                                                     ;; Population per sqaure mile from 2011 census - scaled by 0.01
     town-type = "Urban Rich" [ set population-density 180.37 ]
   )

;; Set workplace-density

  (ifelse
    town-type = "Urban Poor" [ set workplace-density 72.81 ]                                                                       ;; Workplaces per square mile - Scotlands Business Base
    town-type = "Urban Rich" [ set workplace-density 219.62 ]
   )

;; Set School density

   (ifelse
    town-type = "Urban Poor" [ set school-density 2.82 ]                                                                           ;; Schools per square mile - School catchement data 2021
    town-type = "Urban Rich" [ set school-density 3.64 ]
   )

  set efficiency 33                                                                                                                ;; fuel efficiency - UK Department of Transport (MPG)

  set vl 1                                                                                                                         ;; Linear value of time parameter - set to 1 for all agents

  generate-env
  generate-workplaces
  generate-schools

  if town-type = "Urban Poor" [
    let wage-proportions [.014	.057 .125	.206	.29 .37	.444	.571	.665	.74	.798	.843	.878	.926	.954	.971	.989 1 ]         ;; Cumulative proportions for wage catagories initialised above as "wage-list"
    generate-smokers  wage-proportions 0.8797 0.892 0.9817                                                                         ;; Transport Type Proportions "Car / Bike / Walk"
    generate-outlet-type  "Retailer" orange 16.6 8.63 0.943 7.77                                                                   ;; Retailer initialisation "Type / Colour / Density / Mean Price / Standard Deviation / Min Price"
  ]

  if town-type = "Urban Rich" [
    let wage-proportions  [.01	.035	.077	.13	.187	.246	.303	.412	.504	.585	.654	.714	.763	.84	.892	.928	.967 1 ]     ;; Cumulative proportions for wage catagories initialised above as "wage-list"
    generate-smokers  wage-proportions 0.7847 0.8204 0.947                                                                         ;; Transport Type Proportions "Car / Bike / Walk"
    generate-outlet-type  "Retailer" orange 28.16 8.38 0.921 7.74                                                                  ;; Retailer initialisation "Type / Colour / Density / Mean Price / Standard Deviation / Min Price"
  ]

  set-fuel-price
  introduce-policies

  set outlet-list [self] of outlets                                                                                                ;; outlet-list is a list structure but its order is random
  set outlet-index range length outlet-list                                                                                        ;; create index of that ordered list

  set mode "all_at_home"
  set day 0
  update-plots

end


to generate-env  ;; Creates a network of nodes and links (Roads and intersections)

  ask patches [sprout 1]

  ask turtles [
    set breed nodes
    set size 0
    create-links-with nodes-on neighbors4
    set is-a-node 1
  ]

ask patches [set pcolor 7]

ask links [set color 0 set thickness 0.1 ]

end

to generate-workplaces

  if workplace-density > ( (count nodes) / ( world-width * world-height / 1000 ) ) [              ;; If workplace-density is greater than node density then sets workplace-density to node density
   set workplace-density ( (count nodes) / ( world-width * world-height / 1000 ) )
  ]

  create-workplaces ( round ( (world-width * world-height / 1000 ) * workplace-density )) [       ;; divided by 1000 to scale area to 1 square mile

    move-to one-of nodes with [ is-a-workplace = 0 ]
    ask nodes-here [ set is-a-workplace 1 ]
    set color blue
    set shape "box"
    set size 0.5

    ]

end

to generate-smokers [t-wage-proportions car-proportion walk-proportion bike-proportion ]

  set wage-proportions-list t-wage-proportions


  create-smokers (round ( population-density * ( world-width * world-height / 1000 ))) [

;;;;;;;;;;;;;;;;;;;;;;;;; Transport Type
    let rand random-float 1.0
    set transport-type (ifelse-value
        rand < car-proportion [ "car" ]
        rand < walk-proportion [ "walk" ]
        rand < bike-proportion [ "bike" ]
        [ "home" ]
        )
    if transport-type = "home" [ die ]                                                                             ;; Transport type proportions do not add up to 1
                                                                                                                   ;; Tobacco Town does not model those that work from home

    (ifelse
        transport-type = "car" [set speed 19.9]
        transport-type = "walk" [set speed 2.1]
        transport-type = "bike" [set speed 7.5]
        )

;;;;;;;;;;;;;;;;;;;;;;;;; Wage Cumulative Proportions

    let rnd-wage random-float 1.0
    let index-wage 0
    while [index-wage < length wage-proportions-list - 1 and rnd-wage > item index-wage wage-proportions-list]
    [set index-wage index-wage + 1]

    set wage item index-wage wage-list
    set wage ( wage - random 50 )                                                                                   ;; Randomises wage within wage catagory
    set hourly-wage (wage / 40 )                                                                                    ;; set hourly wage - assumes 40 hour work week

;;;;;;;;;;;;;;;;;;;;;;;;; Smoking rate cumulative proportions

    let rnd-smoke random-float 1.0
    let index-smoke 0
    while [index-smoke < length smoking-proportions-list - 1 and rnd-smoke > item index-smoke smoking-proportions-list]
    [set index-smoke index-smoke + 1]

    let cigarettes item index-smoke cigarette-list
    set smoking-rate cigarettes

    set discount (discount-rate-lower-limit + random-float ( 1 - discount-rate-lower-limit) )                        ;; Uniform distribution ∈ (0.54, 1) Discount term devalues cigarettes purchased in the future

    let x_work 0
    let y_work 0
    set color white
    set shape "person"
    set size 0.7
    set inventory random 40
    set smokers-home one-of nodes

    ask smokers-home [

      set color 36
      set shape "house"
      set size 0.7
      set is-a-home 1

    ]

    move-to smokers-home
    set work one-of nodes with [ is-a-workplace = 1 and distance myself > 0 ]                                      ;; Home and workplace at different nodes

    let s_work work
    let home_work_nodes 0
    ask smokers-home [
      set home_work_nodes nw:turtles-on-path-to s_work
    ]

    set commute-nodes turtle-set home_work_nodes
    set commute-path home_work_nodes
    ;; Stores nodes on smokers commute

    set total-cost-per-pack []                                                                                     ;;initialise list for recording individual cost for purchase

  ]

end

to generate-outlet-type [ t-name t-color t-prop  t-dist-l t-dist-m t-dist-r  ]
    create-outlets ( round ( (world-width * world-height / 1000 ) * random-normal t-prop 0.5 )) [
    set outlet-type t-name
    set color t-color
    set shape "target"
    set size 0.7
    set price price-normal-dist t-dist-l t-dist-m t-dist-r
    set outlet-place one-of nodes with [ is-an-outlet = 0 ]
    ask outlet-place [
      set is-an-outlet 1
    ]
    move-to outlet-place
  ]

end

to generate-schools

    create-schools ( school-density * (world-height * world-width / 1000 ) ) [
    set color 55
    set shape "tree"
    set size 0.7
    move-to one-of nodes
  ]
end

to-report price-normal-dist [mid dev mmin]                                   ;; generates a retailer specific pack price from a truncated normal distribution
  let result random-normal mid dev
  if result < mmin
    [ report price-normal-dist mid dev mmin ]
  report result
end

to set-fuel-price
  ask smokers [
    (ifelse
      transport-type = "car"
      [set fuel-price 5.92 ]                                                 ;; UK Fuel price per gallon 2018
      [set fuel-price 0 ]                                                    ;; Fuel price for other transport types is 0
      )
  ]
end

to go
  if day = number-of-days [                                                  ;; Stop simulation at end of period
    report-end-state
    stop
  ]

  move-smokers

end

to run-exp ;; For running repeated simulations decreasing density every time

  if day = number-of-days [
    report-end-state
    set-current-plot "Cost and Density"
    plotxy end-density average-costs

    ifelse retailer-density-cap > 10 [
    set retailer-density-cap retailer-density-cap - density-cap-reduction-interval
    setup
    go
    ]
      [stop]
    ]

  move-smokers

end

to move-smokers

    ifelse move-smokers? = true [
    ask n-of 1 smokers [pen-down set pen-size 4]                   ;; Records 1 smokers path - changes each day

    if mode = "all_at_home" [
    ask smokers [
    set inventory (inventory - smoking-rate)                       ;; Smoke cigarettes
    ifelse inventory < smoking-rate [purchase] [commute] ]         ;; Purchase decision

    set mode "go_to_work"
    set flag 1                                                     ;; Flag set to 1 if agents are moving
    ]

    while [mode != "all_at_home"][                                 ;; While smokers are not at home they are commuting

    if mode != "all_at_home" and flag = 1[
      set flag 0
      ask smokers[

      ifelse length journey > 1[
        set journey but-first journey
        let new-pos first journey
        move-to new-pos

        set flag 1                                                 ;;as there is still nodes left in the journey then flag that an agent is still moving
      ][

        if day-state = "to_work" and mode = "go_home" [            ;;if all the agents are at work then set a journey for home

          set day-state "to_home"

          set journey reverse commute-path
          set journey-length length journey
          set flag 1                                                ;; set that an agent is moving
          set color white
        ]
      ]
    ]
      wait 0.1                                                      ;; makes animation more visible
  ]


  if mode = "go_to_work" and flag = 0[                              ;; if all the agents are at work time to go home
    set mode "go_home"
    set flag 1
    wait 1                                                          ;; pause when all at work
  ]

  if mode = "go_home" and flag = 0[                                 ;; test to see if all agents have reached home
    set mode "all_at_home"
    set flag 1
    set day (day + 1)

    ask smokers [pen-up]
    clear-drawing
    wait 1 ;; pause when all at home
    ]
  ]
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; If move-agents? is set to off

    [ask smokers [
    set inventory ( inventory - smoking-rate )
    if inventory < smoking-rate [
      purchase
      set color white                                                ;; Color flashes white -> red -> white if purchasing
    ]
   ]
    set day (day + 1)
  ]

end

to purchase
  set color red
  find-optimum-path
  get-costs

  ;;Update all purchase related variables and lists

  set inventory ( inventory + ( packs-purchased * 20) )
  set purchases-made ( purchases-made + 1 )
  set total-cost-per-pack lput total-pack-cost total-cost-per-pack

end

to commute ;; for agents not purchasing cigarettes

    set journey commute-path
    set journey-length length journey
    set day-state "to_work"
end

to find-optimum-path   ;; this will find the outlet that is best on way to work

  let s_list []
  calc-price
    set s_list sort-by [ [?1 ?2 ] -> get-best-tpc  ?1  < get-best-tpc  ?2  ] outlet-index

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Trembling hand - there is a probability of 0.025 that the optimum retailer is not chosen
;; For exact mechanism see Tobacco Town Luke et al. Appendix A

  let index_no 0
  ifelse random-float 1 > 0.025 [                                                                ;; 0.025 = Probability that the best retailer isn't chosen

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

    set selected-outlet item index_no outlet-list

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Setting up route

    if move-smokers? = true [
    let s_commute-path commute-path
    let point_on_commute 0
    let outlet_location 0
    let poc_index 0
    let path_1 0
    let path_2 0
    let path_3 0

    ask selected-outlet[
      set point_on_commute nearest-node
      set poc_index position point_on_commute s_commute-path                   ;; Records position of nearest commute point to retailer on commute-path so it can be split
                                                                               ;; into a journey from home -> point and point -> work
      set outlet_location outlet-place

      ask point_on_commute [
        set path_1 sublist s_commute-path 0 poc_index
        set path_2 nw:turtles-on-path-to outlet_location                       ;; Find path from point to selected retailer
        set path_3 sublist s_commute-path poc_index (length s_commute-path)
      ]
    ]

   set journey (sentence path_1 path_2 reverse bl path_2 path_3)
   set journey-length length journey

  ]
 set day-state "to_work"

end

to-report get-best-tpc [ index] ;; Sorts outlets into list based on TPC
  let cost-at-r 0
  ask  item index outlet-list [
    set  cost-at-r best-tpc
  ]
 report cost-at-r
end

to calc-price
  let cost-at-r 0 ;; cost-at-r is the per pack cost for purchasing an optimal quantity of cigarettes at retailer r

  let s_commute-nodes commute-nodes                                                           ;; Variables for calculation "c_"
  let c_discount discount
  let c_speed speed
  let c_hourly-wage hourly-wage
  let c_inventory inventory
  let c_smoking-rate smoking-rate
  let c_transport-type transport-type
  let c_fuel-price fuel-price

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Calculate the distance off commute to reach the retailer

  ask  outlets [
    set nearest-node min-one-of s_commute-nodes [ distance myself ]
    let nearest-point nearest-node
    let off_path 0
    ask outlet-place [
    set off_path nw:distance-to nearest-point
    ]

    set difference (off_path / 15) ;; Since there are 30 links per mile the distance off path must be divided by 30 and the multiplied by 2 (distance there and back) to get the difference

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Calculation of cost-at-r

    let quantity 1                                                                              ;; Start at 1 pack and increase q each iteration
    set current-q quantity
    let min-value 99999

    repeat 100 [                                                                                ;; 100 pack maximum purchase so repeat 100X increasing quantity each iteration

      let c_price price
      if quantity mod 10 = 0 and buy-cartons? = true [ set c_price ( ( price * 7.63 ) / 10 ) ]  ;; If buy-cartons? set to true then carton multiplier sets pack price to 0.763 * price for multiples of 10 packs


      let qq-list n-values quantity [x -> x + 1]                                                ;; Generates a list of values from 1 to q eg [ 1 2 3 4 5 6] for q=6, this is for the "sum-function" below

      let sum-function sum (map [ x -> c_discount ^ floor ((20 * (x - 1) + c_inventory) / c_smoking-rate) ] qq-list)  ;; This function uses the smokers discount rate to devalue packs purchased in the future

      let current-value (  ((( difference / c_speed + 1 / 12) * c_hourly-wage * vl + difference * c_fuel-price / efficiency + quantity * c_price ) / sum-function ))  ;; Cost calculation

      if current-value < min-value [                                                            ;; If newest value is lower, min-value is updated and current-q and cost-at-r are recorded
        set min-value current-value
        set current-q quantity
        set cost-at-r   (( difference / c_speed + 1 / 12) * c_hourly-wage * vl + difference * c_fuel-price / efficiency + current-q * c_price ) / current-q
      ]

      set quantity quantity + 1                                                                 ;; Increases quantity for next repeat

    ] ;; 100 loop

    set best-tpc cost-at-r                                                                    ;; saves cost-at-r for each retailer
    set best-quantity current-q

  ] ;; Ask oulets loop


end

to get-costs

  set total-pack-cost [best-tpc] of selected-outlet

end

to introduce-policies

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Density Cap

let outlet-reduction-factor (1 - (retailer-density-cap * 0.01 ))

if retailer-density-cap != 100 [
 ask n-of (count outlets * outlet-reduction-factor) outlets [
      ask outlet-place [
        set is-an-outlet 0
        set size 1
        set shape "x"
        set color red]
      die
      ]
  ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; School buffer

let school-buffer-factor (ifelse-value
    school-buffer = "None" [ 0 ]
    school-buffer = "500 Feet" [ 3 ]
    school-buffer = "1000 Feet" [ 6 ]
    school-buffer = "1500 Feet" [ 9 ]
    )
if school-buffer != "None" [
  ask schools [
    ask outlets [
        if distance myself <= school-buffer-factor [
      ask outlet-place [
        set is-an-outlet 0
        set size 1
        set shape "x"
        set color red]
      die
       ]
     ]
   ]
 ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Retailer Minimum Distance

  let retailer-buffer-factor (ifelse-value
    retailer-min-distance-buffer = "None" [ 0 ]
    retailer-min-distance-buffer = "500 Feet" [ 3 ]
    retailer-min-distance-buffer = "1000 Feet" [ 6 ]
    retailer-min-distance-buffer = "1500 Feet" [ 9 ]
    )
if retailer-min-distance-buffer != "None" [
  ask outlets [
    if any? other outlets in-radius retailer-buffer-factor [
       ask outlet-place [
        set is-an-outlet 0
        set size 1
        set shape "x"
        set color red]
      die
     ]
   ]
 ]

  set outlet-list [self] of outlets
  set outlet-index range length outlet-list  ;; Update outlet list and index


end

to report-end-state

  ask smokers [

    if purchases-made != 0
    [set smoker-average-costs ( ( sum total-cost-per-pack) / purchases-made )]

  ]

  set average-costs ( mean [ smoker-average-costs ] of smokers with [purchases-made > 0])
  set end-density  ( count outlets ) / (world-height * world-width / 1000)

  output-print (word "TPC (£): " (precision average-costs 2) " Density: " (precision end-density 2) )


end
@#$#@#$#@
GRAPHICS-WINDOW
208
8
650
451
-1
-1
13.563
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
7
225
63
259
SETUP
reset-model
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
8
33
205
78
town-type
town-type
"Urban Poor" "Urban Rich"
0

MONITOR
654
10
770
55
Population Density
count smokers / ((world-height * world-width) / 1000 )
1
1
11

PLOT
775
188
999
359
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
775
12
999
183
Wage Distribution
Weekly income (£)
Count
0.0
2500.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "histogram [precision wage -2] of smokers"

MONITOR
654
59
770
104
Total Retailer Density
count outlets / (world-height * world-width / 1000)
1
1
11

MONITOR
654
107
770
152
School Density
count schools / (world-width * world-height / 1000 )
1
1
11

MONITOR
503
455
588
500
NIL
mode
17
1
11

BUTTON
65
225
121
259
GO
go
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
3
287
204
320
retailer-density-cap
retailer-density-cap
10
100
10.0
5
1
%
HORIZONTAL

CHOOSER
3
357
204
402
school-buffer
school-buffer
"None" "500 Feet" "1000 Feet" "1500 Feet"
0

CHOOSER
3
405
204
450
retailer-min-distance-buffer
retailer-min-distance-buffer
"None" "500 Feet" "1000 Feet" "1500 Feet"
0

BUTTON
3
454
130
487
Introduce Policy
introduce-policies\n\n
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
593
455
650
500
NIL
day
17
1
11

SLIDER
8
81
206
114
number-of-days
number-of-days
1
30
3.0
1
1
days
HORIZONTAL

MONITOR
655
156
771
201
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
19
263
169
283
POLICY TESTING
16
0.0
0

SWITCH
8
117
205
150
buy-cartons?
buy-cartons?
1
1
-1000

PLOT
1005
189
1229
360
Cost and Density
Retailers per square mile
TPC (£)
0.0
10.0
8.0
10.0
true
false
"" ""
PENS
"pen-0" 1.0 2 -2674135 true "" ""

TEXTBOX
1015
363
1226
407
TPC (Total Pack Cost £) - Combined travel and purchase cost per pack
10
0.0
1

TEXTBOX
657
405
757
423
Retailer (target)\n
11
25.0
1

TEXTBOX
658
420
758
438
Workplace (box)\n
11
105.0
1

TEXTBOX
658
434
758
452
School (tree)
11
55.0
1

SWITCH
8
153
206
186
move-smokers?
move-smokers?
1
1
-1000

OUTPUT
1004
12
1227
151
9

SLIDER
3
322
204
355
density-cap-reduction-interval
density-cap-reduction-interval
1
10
5.0
1
1
NIL
HORIZONTAL

BUTTON
123
225
203
260
EXPERIMENT
run-exp
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
657
392
773
410
KEY:
11
0.0
1

BUTTON
1004
151
1227
185
Clear Output
clear-output
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
656
203
774
268
Tobacco Town ABM area is 10 sqaure miles. Set to 1 for speed
11
0.0
1

SLIDER
7
189
205
222
discount-rate-lower-limit
discount-rate-lower-limit
0
1
0.54
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

Tobacco Town NetLogo - Agent Based Model

A replication of the Tobacco Town ABM for a "Rich" and "Poor" area of Glasgow, Scotland.

The Tobacco Town Agent Based Model was created in 2017 by Luke et al. to investigate the potential effects of tobacco retailer reduction policies in an abstract environment of four different Californian town types. The model analysed how the expense of obtaining cigarettes, which comprise both the direct cost of the product and the additional cost of traveling to a tobacco retailer, varied due to retailer reduction policies. When assessing the policy scenarios, the fundamental aspect explored by the model is the influence of retail density dynamics on overall costs.

This model is a reproduction of the Tobacco Town agent-based model in a Scottish context by using epidemiological, social and retailer empirical data representing two different areas of Glasgow.


## HOW IT WORKS

The model is designed to assess how tobacco retailer policy options affect the direct and indirect costs of purchasing cigarettes in a simulated environment.

The environment consists of a grid of "roads" and intersections. Agents have both a home and a workplace location assigned to them - for simplicity these locations lie at intersections.

Retailers, Schools and Workplaces are generated with real densities from the 4 availble town types based on empirical data.

Agents decide to purchase cigarettes if their inventory is less than their smoking rate. When they decide to purchase they select a retailer using an optimisation function including many different variables in which they have perfect information on tobacco price and the distance to a retailer.

Once a retailer is selected the agents divert their morning commute to travel to the retailer travelling from home to work. The agents commute home in the evening and smoke their inventory of cigarettes - set as the smoking-rate.

#### Environment
The model environment consists of a road grid representing a 1.024 square mile area. Two different town types (Urban Rich, Urban Poor) are simulated with Retailers, workplaces, and Schools randomly positioned at intersections using area specific spatial density data. 

#### Agents
The agents represent adult smokers and are generated based on population density for each town type. Agents make purchase decisions and commute from home to work, potentially buying tobacco en route. They choose retailers and quantities to minimize overall costs per pack, factoring in time, travel expenses, and cigarette prices.

Agents follow a daily routine with morning and evening periods. In the morning, agents decide whether to purchase tobacco if their initialised inventory is less than their smoking rate, then commute to work, buying tobacco on the way. Agents choose an optimal retailer and an optimum purchase quantity using a rational decision rule and calculation<sup>1</sup>. In the evening, agents commute home and consume tobacco based on their smoking rate.

Agents have several time-invariant attributes of smoking rate, home and work locations and commute, wage, transportation mode, and a discount rate. These variables impact purchase decisions and costs. the Family probability attribute and subsequent child generation present in the original model, is omitted in this NetLogo version.
 
<sup>1</sup>Detailed in Tobacco Town technical appendix https://ajph.aphapublications.org/doi/suppl/10.2105/AJPH.2017.303685/suppl_file/luke_201618559_suppl_appendixa.docx

#### Policy Testing
The model tests the effects of various tobacco retailer reduction policies, allowing alteration of baseline parameters for diverse policy testing. Policies include:

1) Retailer Density Cap (% of baseline density - retailers randomly removed)
2) Retailer Distance Buffer (500, 1000 and 1500Ft)
3) School Distance Buffer (500, 1000 and 1500Ft)

NB. Retailer Removal is not included in this model as retailer type data is not available for Scotland.

#### Pathfinding

Smokers are assigned a `commute_path` in model setup that is one of the optimum routes between home and work, this is done using `nw:turtles-on-path-to`. 

When a retailer is being selected, agents find the closest point on their commute path to the retailer and find a path off their commute to the retailer. This can be visualised when `move-agents?` is set to on.

#### Data
Empirical data from surveys, census, and other sources initializes the model. Data includes retailer types, prices, and densities. For the Glasgow model, census data from 2011 and approximated wage data are used. The model runs for 30 days, collecting aggregate data on costs, distances, travel time, purchase details, and retailer density.

## HOW TO USE IT

### Setup

To **setup** the model:

1) Select the `town-type` using the dropdown menu. 

2) Choose a `number-of-days` to simulate for each run (10 - 30 reccomended).

3) Toggle `buy-cartons?` to on to introduce a carton (10 packs) discount at 7.63 * pack price. 

This is not applicible to the Scottish environment due to UK tobacco regulations, but is included in the Tobacco Town ABM.

4) Toggle `move-agents?` to introduce an animation, this will slow the simulation down significantly but is useful to visualse agent behaviour.

5) Choose a `density-cap-reduction-interval`.
 
This is the value that the density-cap reduces by each run (5 reccomended).

6) You can experiemnt by implementing different school and retailer distance buffers using the dropdown menus in the **Policy Testing** section.

Click **Introduce Policy** to see the effect. Removed retailers are represented by a red "X" on the world view.

NB. These policies are not used when **EXPERIMENT** is clicked but will persist for an individual run.

### GO

**GO** beings an individual run of a single simulation of the length `number-of-days`.

1) Select policy profile using the slider and drop down menus.

2) Click **Introduce Policy**.

3) Click **GO**.

4) The TPC - Total Pack Cost (£) - and Density are reported in the output.

### EXPERIMENT 
1) Click **EXPERIMENT** to begin. The simulation will run for `number-of-days` and then decrease the retailer density from 100% to 10% of baseline density by the selected interval every repetition.

After each repetition, cost versus density is plotted.


## THINGS TO NOTICE

The relationship between retailer density and cost is predicted to be non-linear.

The output plot of TPC and retailer density should reproduce this relationship. 

## THINGS TO TRY

The model is designed to showcase the Tobacco Town model although it is possible to run experiments using the behvaiour space.

You can try changing the world size to assess the impact this has on the cost density relationship.


## RELATED MODELS

Tobacco Town ABM.

## CREDITS AND REFERENCES

Luke DA, Hammond RA, Combs T, Sorg A, Kasman M, Mack-Crane A, Ribisl KM, Henriksen L. Tobacco Town: Computational Modeling of Policy Options to Reduce Tobacco Retailer Density. Am J Public Health. 2017 May;107(5):740-746. doi: 10.2105/AJPH.2017.303685. Erratum in: Am J Public Health. 2017 Oct;107(10):e1. PMID: 28398792; PMCID: PMC5388950.
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
