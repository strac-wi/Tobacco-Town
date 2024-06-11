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
  vl ;; Linear value of time - set to 1
  wage-proportions-list
  wage-list
  smoking-proportions-list
  cigarette-list
  outlet_list   ;; fixed list of outlets
  outlet_index  ;; a list of indexes to the outlets
  mode ;; "go_to_work" "go_home" "all_at_home"
  day
  average-costs
  average-purchase-costs
  average-travel-costs
  average-distance
  average-purchase-quantity
  end-density
  setup-seed

  median-cost        ;; list of median purchase cost of cigarettes for each patch
  median-quantity    ;; list of median quantity of purchased cigarettes for each patch
  median-wage        ;; list of median wage of smokers for each patch
  median-rate        ;; list of median smoking rate of smokers for each patch
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
  my-neighbourhood
]
nodes-own [
  place
  is-an-outlet
  is-a-workplace
  is-a-school
  is-a-home
  debug
]
outlets-own [
  outlet_place
  price
  outlet-type
  difference
  current-q
  best-price ;;; this is a holding value calculated for each smoker
  best-quantity
]
workplaces-own [
place
]
patches-own [
  smokers-median-cost
  smokers-median-quantity
  smokers-median-wage
  smokers-median-rate
  smokers-median-route
]



to setup
  set setup-seed 10
  if random-spatial? = false [random-seed setup-seed]
  ;print "Start setup"
  reset-timer
  clear-all
  reset-ticks

  ;; generate the nodes and links
  generate-env
  ;; Set population-density, workplace-density, school density
  (ifelse
    town-type = "Suburban Poor" [
      set population-density 20.8
      set workplace-density 71.01
      set school-density 1.41
      ifelse override-wages? = false and override-rates? = false [
        generate-workplaces workplace-density "all"
        generate-schools school-density "all"
      ]
      [
        generate-workplaces workplace-density "left"
        generate-schools school-density "left"
        generate-workplaces workplace-density "right"
        generate-schools school-density "right"
      ]
    ]
    town-type = "Suburban Rich" [
      set population-density 18.7
      set workplace-density 64.3
      set school-density 1.09
      ifelse override-wages? = false and override-rates? = false [
      generate-workplaces workplace-density "all"
      generate-schools school-density "all"
      ]
      [
        generate-workplaces workplace-density "left"
        generate-schools school-density "left"
        generate-workplaces workplace-density "right"
        generate-schools school-density "right"
      ]
    ]
    town-type = "Urban Poor" [
      set population-density 38.3
      set workplace-density 72.81
      set school-density 4.49
      ifelse override-wages? = false and override-rates? = false [
        generate-workplaces workplace-density "all"
        generate-schools school-density "all"
      ]
      [
        generate-workplaces workplace-density "left"
        generate-schools school-density "left"
        generate-workplaces workplace-density "right"
        generate-schools school-density "right"
      ]

    ]
    town-type = "Urban Rich" [
      set population-density 31.2
      set workplace-density 219.62
      set school-density 2.79
      ifelse override-wages? = false and override-rates? = false [
        generate-workplaces workplace-density "all"
        generate-schools school-density "all"
      ]
      [
        generate-workplaces workplace-density "left"
        generate-schools school-density "left"
        generate-workplaces workplace-density "right"
        generate-schools school-density "right"
      ]
    ]
    town-type = "Urban Poor | Urban Rich" [
      ;; Urban poor
      set population-density 38.3
      set workplace-density 72.81
      set school-density 4.49
      generate-workplaces workplace-density "left"
      generate-schools school-density "left"
      ;; Urban rich
      set population-density 31.2
      set workplace-density 219.62
      set school-density 2.79
      generate-workplaces workplace-density "right"
      generate-schools school-density "right"
    ]
    town-type = "Urban Poor (no work or outlets) | Urban Rich" [
      ;; Urban rich
      set population-density 31.2
      set workplace-density 219.62
      set school-density 2.79
      generate-workplaces workplace-density "right"
      generate-schools school-density "right"
    ]
  )

;  ;; Set workplace-density
;  (ifelse
;    town-type = "Suburban Poor" [ set workplace-density 71.01 ]
;    town-type = "Suburban Rich" [ set workplace-density 64.3 ]
;    town-type = "Urban Poor" [ set workplace-density 72.81 ]
;    town-type = "Urban Rich" [ set workplace-density 219.62 ]
;  )
;
;  (ifelse
;    town-type = "Suburban Poor" [ set school-density 1.41 ]
;    town-type = "Suburban Rich" [ set school-density 1.09 ]
;    town-type = "Urban Poor" [ set school-density 4.49 ]
;    town-type = "Urban Rich" [ set school-density 2.79 ]
;  )

  set efficiency 18.6 ;; Based on US Gov Data
  set vl 1 ;; Linear value of time parameter - set to 1 for all agents

;  generate-env
;  generate-workplaces-old
;  generate-schools

  if random-spatial? = false [random-seed new-seed]

  if town-type = "Suburban Poor" [
    let wage-proportions  [0.067 0.207 0.442 0.546 0.689 0.894 0.962 0.992 0.996 1.0]
    ifelse override-rates? = false and override-wages? = false [
      (ifelse
        smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.9306  0.987  0.9817 "all"]
        smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.9306  0.987  0.9817 "all"]
        smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.9306  0.987  0.9817 "all"]
        smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.9306  0.987  0.9817 "all"]
        smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.9306  0.987  0.9817 "all"]
        smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.9306  0.987  0.9817 "all"]
        smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.9306  0.987  0.9817 "all"]
        smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.9306  0.987  0.9817 "all"]
      )
      if random-spatial? = false [random-seed setup-seed]
      ;generate-smokers  wage-proportions 0.9306  0.987  0.9817
      generate-outlet-type  "Convenience" orange 2.25 5.81 1.13 4.09 "all"
      generate-outlet-type  "Drug" orange 0.45 5.52 0.86 4.27 "all"
      generate-outlet-type  "Grocery" orange 0.76 6.06 1.21 4.46 "all"
      generate-outlet-type  "Liquor" orange 0.4  6.35 1.21 4.61 "all"
      generate-outlet-type  "Mass" orange 0.11 6.12 0.86 4.88 "all"
      generate-outlet-type  "Tobacconist" orange 0.16 5.77 0.45 4.89 "all"
      if random-spatial? = false [random-seed new-seed]
    ]
    ;; otherwise (generate left and right separately)
    [
      (ifelse
        smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.9306  0.987  0.9817 "left" generate-smokers-V  wage-proportions 0.9306  0.987  0.9817 "right"]
        smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.9306  0.987  0.9817 "left" generate-smokers-V-routes  wage-proportions 0.9306  0.987  0.9817 "right"]
        smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.9306  0.987  0.9817 "left" generate-smokers-VC-rate  wage-proportions 0.9306  0.987  0.9817 "right"]
        smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.9306  0.987  0.9817 "left" generate-smokers-VC-inventory wage-proportions 0.9306  0.987  0.9817 "right"]
        smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.9306  0.987  0.9817 "left" generate-smokers-VC-wage wage-proportions 0.9306  0.987  0.9817 "right"]
        smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.9306  0.987  0.9817 "left" generate-smokers-VC-transport wage-proportions 0.9306  0.987  0.9817 "right"]
        smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.9306  0.987  0.9817 "left" generate-smokers-VC-routes wage-proportions 0.9306  0.987  0.9817 "right"]
        smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.9306  0.987  0.9817 "left" generate-smokers  wage-proportions 0.9306  0.987  0.9817 "right"]
      )
      if random-spatial? = false [random-seed setup-seed]
      ;generate-smokers  wage-proportions 0.9306  0.987  0.9817
      generate-outlet-type  "Convenience" orange 2.25 5.81 1.13 4.09 "left"
      generate-outlet-type  "Drug" orange 0.45 5.52 0.86 4.27 "left"
      generate-outlet-type  "Grocery" orange 0.76 6.06 1.21 4.46 "left"
      generate-outlet-type  "Liquor" orange 0.4  6.35 1.21 4.61 "left"
      generate-outlet-type  "Mass" orange 0.11 6.12 0.86 4.88 "left"
      generate-outlet-type  "Tobacconist" orange 0.16 5.77 0.45 4.89 "left"
      generate-outlet-type  "Convenience" orange 2.25 5.81 1.13 4.09 "right"
      generate-outlet-type  "Drug" orange 0.45 5.52 0.86 4.27 "right"
      generate-outlet-type  "Grocery" orange 0.76 6.06 1.21 4.46 "right"
      generate-outlet-type  "Liquor" orange 0.4  6.35 1.21 4.61 "right"
      generate-outlet-type  "Mass" orange 0.11 6.12 0.86 4.88 "right"
      generate-outlet-type  "Tobacconist" orange 0.16 5.77 0.45 4.89 "right"

      if random-spatial? = false [random-seed new-seed]
    ]
  ]

  if town-type = "Suburban Rich" [
    let wage-proportions  [0.013 0.026 0.059 0.093 0.178 0.383 0.554 0.822 0.941 1.0]
    ifelse override-rates? = false and override-wages? = false [
      (ifelse
        smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.8697 0.8824 0.9231 "all"]
        smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.8697 0.8824 0.9231 "all"]
        smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.8697 0.8824 0.9231 "all"]
        smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.8697 0.8824 0.9231 "all"]
        smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.8697 0.8824 0.9231 "all"]
        smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.8697 0.8824 0.9231 "all"]
        smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.8697 0.8824 0.9231 "all"]
        smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.8697 0.8824 0.9231 "all"]
      )
      if random-spatial? = false [random-seed setup-seed]
      ;generate-smokers  wage-proportions 0.8697 0.8824 0.9231
      generate-outlet-type  "Convenience" orange 1.24 6.37 1.29 3.99 "all"
      generate-outlet-type  "Drug" orange 0.25 6.29 1.40 4.34 "all"
      generate-outlet-type  "Grocery" orange 0.42 6.49 1.31 4.24 "all"
      generate-outlet-type  "Liquor" orange  0.22 6.34 1.09 5.09 "all"
      generate-outlet-type  "Mass" orange 0.06 6.54 0.0001 6.54 "all"
      generate-outlet-type  "Tobacconist" orange   0.09  6.18 1.81 4.99 "all"
      if random-spatial? = false [random-seed new-seed]
    ]
    ;; otherwise (generate left and right separately)
    [
      (ifelse
        smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.8697 0.8824 0.9231 "left" generate-smokers-V  wage-proportions 0.8697 0.8824 0.9231 "right"]
        smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.8697 0.8824 0.9231 "left" generate-smokers-V-routes  wage-proportions 0.8697 0.8824 0.9231 "right"]
        smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.8697 0.8824 0.9231 "left" generate-smokers-VC-rate  wage-proportions 0.8697 0.8824 0.9231 "right"]
        smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.8697 0.8824 0.9231 "left" generate-smokers-VC-inventory wage-proportions 0.8697 0.8824 0.9231 "right"]
        smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.8697 0.8824 0.9231 "left" generate-smokers-VC-wage wage-proportions 0.8697 0.8824 0.9231 "right"]
        smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.8697 0.8824 0.9231 "left" generate-smokers-VC-transport wage-proportions 0.8697 0.8824 0.9231 "right"]
        smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.8697 0.8824 0.9231 "left" generate-smokers-VC-routes wage-proportions 0.8697 0.8824 0.9231 "right"]
        smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.8697 0.8824 0.9231 "left" generate-smokers  wage-proportions 0.8697 0.8824 0.9231 "right"]
      )
      if random-spatial? = false [random-seed setup-seed]
      ;generate-smokers  wage-proportions 0.8697 0.8824 0.9231
      generate-outlet-type  "Convenience" orange 1.24 6.37 1.29 3.99 "left"
      generate-outlet-type  "Drug" orange 0.25 6.29 1.40 4.34 "left"
      generate-outlet-type  "Grocery" orange 0.42 6.49 1.31 4.24 "left"
      generate-outlet-type  "Liquor" orange  0.22 6.34 1.09 5.09 "left"
      generate-outlet-type  "Mass" orange 0.06 6.54 0.0001 6.54 "left"
      generate-outlet-type  "Tobacconist" orange   0.09  6.18 1.81 4.99 "left"
      generate-outlet-type  "Convenience" orange 1.24 6.37 1.29 3.99 "right"
      generate-outlet-type  "Drug" orange 0.25 6.29 1.40 4.34 "right"
      generate-outlet-type  "Grocery" orange 0.42 6.49 1.31 4.24 "right"
      generate-outlet-type  "Liquor" orange  0.22 6.34 1.09 5.09 "right"
      generate-outlet-type  "Mass" orange 0.06 6.54 0.0001 6.54 "right"
      generate-outlet-type  "Tobacconist" orange   0.09  6.18 1.81 4.99 "right"
      if random-spatial? = false [random-seed new-seed]
    ]
  ]


  if town-type = "Urban Poor" [
    let wage-proportions [0.078 0.154 0.318 0.452 0.632 0.786 0.892 0.966 0.991 1.0]
    ifelse override-rates? = false and override-wages? = false [
      (ifelse
        smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.8797 0.892 0.9817 "all"]
        smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.8797 0.892 0.9817 "all"]
        smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.8797 0.892 0.9817 "all"]
        smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.8797 0.892 0.9817 "all"]
        smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.8797 0.892 0.9817 "all"]
        smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.8797 0.892 0.9817 "all"]
        smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.8797 0.892 0.9817 "all"]
        smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.8797 0.892 0.9817 "all"]
      )
      if random-spatial? = false [random-seed setup-seed]
      ;generate-smokers  wage-proportions 0.8797 0.892 0.9817
      generate-outlet-type  "Convenience" orange 6.59 6.71 1.32 4.39 "all"
      generate-outlet-type  "Drug" orange 1.33 6.08 1.47 4.28 "all"
      generate-outlet-type  "Grocery" orange 2.21 6.99 1.64 4.50 "all"
      generate-outlet-type  "Liquor" orange  1.18 7.37 1.07 5.64 "all"
      generate-outlet-type  "Mass" orange 0.31 8.08 0.0001 8.08 "all"
      generate-outlet-type  "Tobacconist" orange 0.47 4.91 0.70 4.50 "all"
      if random-spatial? = false [random-seed new-seed]
    ]
    ;; otherwise (generate left and right separately)
    [
      (ifelse
        smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.8797 0.892 0.9817 "left" generate-smokers-V  wage-proportions 0.8797 0.892 0.9817 "right"]
        smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.8797 0.892 0.9817 "left" generate-smokers-V-routes  wage-proportions 0.8797 0.892 0.9817 "right"]
        smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.8797 0.892 0.9817 "left" generate-smokers-VC-rate  wage-proportions 0.8797 0.892 0.9817 "right"]
        smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.8797 0.892 0.9817 "left" generate-smokers-VC-inventory wage-proportions 0.8797 0.892 0.9817 "right"]
        smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.8797 0.892 0.9817 "left" generate-smokers-VC-wage wage-proportions 0.8797 0.892 0.9817 "right"]
        smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.8797 0.892 0.9817 "left" generate-smokers-VC-transport wage-proportions 0.8797 0.892 0.9817 "right"]
        smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.8797 0.892 0.9817 "left" generate-smokers-VC-routes wage-proportions 0.8797 0.892 0.9817 "right"]
        smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.8797 0.892 0.9817 "left" generate-smokers  wage-proportions 0.8797 0.892 0.9817 "right"]
      )
      if random-spatial? = false [random-seed setup-seed]
      ;generate-smokers  wage-proportions 0.8797 0.892 0.9817
      generate-outlet-type  "Convenience" orange 6.59 6.71 1.32 4.39 "left"
      generate-outlet-type  "Drug" orange 1.33 6.08 1.47 4.28 "left"
      generate-outlet-type  "Grocery" orange 2.21 6.99 1.64 4.50 "left"
      generate-outlet-type  "Liquor" orange  1.18 7.37 1.07 5.64 "left"
      generate-outlet-type  "Mass" orange 0.31 8.08 0.0001 8.08 "left"
      generate-outlet-type  "Tobacconist" orange 0.47 4.91 0.70 4.50 "left"
      generate-outlet-type  "Convenience" orange 6.59 6.71 1.32 4.39 "right"
      generate-outlet-type  "Drug" orange 1.33 6.08 1.47 4.28 "right"
      generate-outlet-type  "Grocery" orange 2.21 6.99 1.64 4.50 "right"
      generate-outlet-type  "Liquor" orange  1.18 7.37 1.07 5.64 "right"
      generate-outlet-type  "Mass" orange 0.31 8.08 0.0001 8.08 "right"
      generate-outlet-type  "Tobacconist" orange 0.47 4.91 0.70 4.50 "right"
      if random-spatial? = false [random-seed new-seed]
    ]
  ]

  if town-type = "Urban Rich" [
    let wage-proportions  [0.041 0.073 0.13 0.188 0.284 0.416 0.534 0.766 0.888 1.0]
    ifelse override-rates? = false and override-wages? = false [
      (ifelse
        smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.7847 0.8204 0.947 "all"]
        smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.7847 0.8204 0.947 "all"]
        smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.7847 0.8204 0.947 "all"]
        smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.7847 0.8204 0.947 "all"]
        smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.7847 0.8204 0.947 "all"]
        smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.7847 0.8204 0.947 "all"]
        smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.7847 0.8204 0.947 "all"]
        smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.7847 0.8204 0.947 "all"]
      )
      if random-spatial? = false [random-seed setup-seed]
      ;generate-smokers  wage-proportions 0.7847 0.8204 0.947
      generate-outlet-type  "Convenience" orange 4.81 6.48 1.68 4.88 "all"
      generate-outlet-type  "Drug" orange 0.97 5.50 1.14 4.93 "all"
      generate-outlet-type  "Grocery" orange 1.61 6.81 1.63 5.09 "all"
      generate-outlet-type  "Liquor" orange 0.86  6.11 1.15 4.93 "all"
      generate-outlet-type  "Mass" orange 0.23 5.09 0.0001 5.09 "all"
      generate-outlet-type  "Tobacconist" orange 0.34  6.68 2.74 3.98 "all"
      if random-spatial? = false [random-seed new-seed]
    ]
    ;; otherwise (generate left and right separately)
    [
      (ifelse
        smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.7847 0.8204 0.947 "left" generate-smokers-V  wage-proportions 0.7847 0.8204 0.947 "right"]
        smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.7847 0.8204 0.947 "left" generate-smokers-V-routes  wage-proportions 0.7847 0.8204 0.947 "right"]
        smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.7847 0.8204 0.947 "left" generate-smokers-VC-rate  wage-proportions 0.7847 0.8204 0.947 "right"]
        smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.7847 0.8204 0.947 "left" generate-smokers-VC-inventory wage-proportions 0.7847 0.8204 0.947 "right"]
        smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.7847 0.8204 0.947 "left" generate-smokers-VC-wage wage-proportions 0.7847 0.8204 0.947 "right"]
        smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.7847 0.8204 0.947 "left" generate-smokers-VC-transport wage-proportions 0.7847 0.8204 0.947 "right"]
        smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.7847 0.8204 0.947 "left" generate-smokers-VC-routes wage-proportions 0.7847 0.8204 0.947 "right"]
        smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.7847 0.8204 0.947 "left" generate-smokers  wage-proportions 0.7847 0.8204 0.947 "right"]
      )
      if random-spatial? = false [random-seed setup-seed]
      ;generate-smokers  wage-proportions 0.7847 0.8204 0.947
      generate-outlet-type  "Convenience" orange 4.81 6.48 1.68 4.88 "left"
      generate-outlet-type  "Drug" orange 0.97 5.50 1.14 4.93 "left"
      generate-outlet-type  "Grocery" orange 1.61 6.81 1.63 5.09 "left"
      generate-outlet-type  "Liquor" orange 0.86  6.11 1.15 4.93 "left"
      generate-outlet-type  "Mass" orange 0.23 5.09 0.0001 5.09 "left"
      generate-outlet-type  "Tobacconist" orange 0.34  6.68 2.74 3.98 "left"
      generate-outlet-type  "Convenience" orange 4.81 6.48 1.68 4.88 "right"
      generate-outlet-type  "Drug" orange 0.97 5.50 1.14 4.93 "right"
      generate-outlet-type  "Grocery" orange 1.61 6.81 1.63 5.09 "right"
      generate-outlet-type  "Liquor" orange 0.86  6.11 1.15 4.93 "right"
      generate-outlet-type  "Mass" orange 0.23 5.09 0.0001 5.09 "right"
      generate-outlet-type  "Tobacconist" orange 0.34  6.68 2.74 3.98 "right"

      if random-spatial? = false [random-seed new-seed]
    ]
  ]

  if town-type = "Urban Poor | Urban Rich" [
    ;; urban poor wage proportions
    let wage-proportions [0.078 0.154 0.318 0.452 0.632 0.786 0.892 0.966 0.991 1.0]
    (ifelse
      smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.8797 0.892 0.9817 "left"]
    )

    ;; urban rich wage proportions
    set wage-proportions  [0.041 0.073 0.13 0.188 0.284 0.416 0.534 0.766 0.888 1.0]
    (ifelse
      smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.7847 0.8204 0.947 "right"]
    )

    if random-spatial? = false [random-seed setup-seed]
    ;; urban poor outlets
    generate-outlet-type  "Convenience" orange 6.59 6.71 1.32 4.39 "left"
    generate-outlet-type  "Drug" orange 1.33 6.08 1.47 4.28 "left"
    generate-outlet-type  "Grocery" orange 2.21 6.99 1.64 4.50 "left"
    generate-outlet-type  "Liquor" orange  1.18 7.37 1.07 5.64 "left"
    generate-outlet-type  "Mass" orange 0.31 8.08 0.0001 8.08 "left"
    generate-outlet-type  "Tobacconist" orange 0.47 4.91 0.70 4.50 "left"

    ;; urban rich outlets
    generate-outlet-type  "Convenience" orange 4.81 6.48 1.68 4.88 "right"
    generate-outlet-type  "Drug" orange 0.97 5.50 1.14 4.93 "right"
    generate-outlet-type  "Grocery" orange 1.61 6.81 1.63 5.09 "right"
    generate-outlet-type  "Liquor" orange 0.86  6.11 1.15 4.93 "right"
    generate-outlet-type  "Mass" orange 0.23 5.09 0.0001 5.09 "right"
    generate-outlet-type  "Tobacconist" orange 0.34  6.68 2.74 3.98 "right"
    if random-spatial? = false [random-seed new-seed]
  ]

  if town-type = "Urban Poor (no work or outlets) | Urban Rich" [
    ;; urban poor wage
    ;; urban poor wage proportions
    let wage-proportions [0.078 0.154 0.318 0.452 0.632 0.786 0.892 0.966 0.991 1.0]
    (ifelse
      smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.8797 0.892 0.9817 "left"]
      smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.8797 0.892 0.9817 "left"]
    )

    ;; urban rich wage proportions
    set wage-proportions  [0.041 0.073 0.13 0.188 0.284 0.416 0.534 0.766 0.888 1.0]
    (ifelse
      smokers-parameters = "Random (V)" [generate-smokers-V  wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random (V routes)" [generate-smokers-V-routes  wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random rate (VC rates)" [generate-smokers-VC-rate  wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random inventory (VC inventory)" [generate-smokers-VC-inventory wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random wage (VC wage)" [generate-smokers-VC-wage wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random transport (VC transport)" [generate-smokers-VC-transport wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "Random routes (VC routes)" [generate-smokers-VC-routes wage-proportions 0.7847 0.8204 0.947 "right"]
      smokers-parameters = "All random (ignore random-spatial?)" [generate-smokers  wage-proportions 0.7847 0.8204 0.947 "right"]
    )

    if random-spatial? = false [random-seed setup-seed]

    ;; urban rich outlets
    generate-outlet-type  "Convenience" orange 4.81 6.48 1.68 4.88 "right"
    generate-outlet-type  "Drug" orange 0.97 5.50 1.14 4.93 "right"
    generate-outlet-type  "Grocery" orange 1.61 6.81 1.63 5.09 "right"
    generate-outlet-type  "Liquor" orange 0.86  6.11 1.15 4.93 "right"
    generate-outlet-type  "Mass" orange 0.23 5.09 0.0001 5.09 "right"
    generate-outlet-type  "Tobacconist" orange 0.34  6.68 2.74 3.98 "right"
    if random-spatial? = false [random-seed new-seed]
  ]

  set-fuel-price
  density-reduction

  set outlet_list [self] of outlets          ;; create a statically ordered list
  set outlet_index range length outlet_list  ;; creat index of that ordered list

  set mode "all_at_home"
  set day 0
  update-plots

  ;print "End setup"
end


to generate-env

  nw:generate-lattice-2d turtles links world-width world-height false
  (foreach (sort turtles) (sort patches) [ [t p] -> ask t [ move-to p ] ])

  ;; creates lattice of nodes equal to world size

  ask turtles [
    set breed nodes
    set shape "circle"
    set color white
    set size 0
    set place "none"
    set is-a-node 1
  ]
end

to generate-workplaces [density neighbourhood]
  ;; find the neighbourhood nodes (left or right or all the space) and calculate the number of workplaces to create
  let neighbourhood-nodes nobody
  let n-workplaces 0
  (ifelse
    neighbourhood = "left" [
      set neighbourhood-nodes nodes with [xcor < max-pxcor / 2]
      if density > ( (count neighbourhood-nodes) / ( world-width * world-height / 200 ) ) [ set density ( (count neighbourhood-nodes) / ( world-width * world-height / 200 ) ) ] ;; If workplace density saturates nodes then workplace-density is set to node-density
      set n-workplaces round ( (world-width * world-height / 200 ) * density )
    ]
    neighbourhood = "right" [
      set neighbourhood-nodes nodes with [xcor > max-pxcor / 2]
      if density > ( (count neighbourhood-nodes) / ( world-width * world-height / 200 ) ) [ set density ( (count neighbourhood-nodes) / ( world-width * world-height / 200 ) ) ] ;; If workplace density saturates nodes then workplace-density is set to node-density
      set n-workplaces round ( (world-width * world-height / 200 ) * density )
    ]
    neighbourhood = "all" [
      set neighbourhood-nodes nodes
      if density > ( (count neighbourhood-nodes) / ( world-width * world-height / 100 ) ) [ set density ( (count neighbourhood-nodes) / ( world-width * world-height / 100 ) ) ] ;; If workplace density saturates nodes then workplace-density is set to node-density
      set n-workplaces round ( (world-width * world-height / 100 ) * density )
    ]
  )
  ;; create workplaces
  create-workplaces ( n-workplaces )  [
    move-to one-of neighbourhood-nodes with [ is-a-workplace = 0 ]
    ask nodes-here [ set is-a-workplace 1 set debug neighbourhood]
    set color grey
    set shape "box"
    set size 0.4
    ]

end

to generate-smokers [t-wage-proportions t-car t-walk t-bike neighbourhood]

;;Smoking rate cumulative proportions

  set smoking-proportions-list [0.006 0.02 0.044 0.072 0.132 0.164 0.193 0.217 0.222 0.465 0.468 0.493 0.495 0.497 0.581 0.584 0.588 0.592 0.889 0.907 0.963 0.966 0.994 0.995 0.996 1.0]
  set cigarette-list [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 20 25 30 35 40 45 50 60]
  let home-nodes nobody
  let n-smokers 0
  (ifelse
    neighbourhood = "left" [
      set home-nodes nodes with [pxcor < max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "right" [
      set home-nodes nodes with [pxcor > max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "all" [
      set home-nodes nodes
      set n-smokers round ( population-density * ( world-width * world-height / 100 ))
    ]
  )

;; Wage Cumulative Proportions

  ;wage-proportions [0.078 0.154 0.318 0.452 0.632 0.786 0.892 0.966 0.991 1.0]
  set wage-proportions-list t-wage-proportions
  set wage-list [5000 12500 20000 30000 42500 62500 87500 125000 175000 250000]



  ;; create smokers
  create-smokers (n-smokers) [

    ;; Smoking rate initialization

    let random-number-smoke random-float 1.0
    let index-smoke 0
    while [index-smoke < length smoking-proportions-list - 1 and random-number-smoke > item index-smoke smoking-proportions-list] [set index-smoke index-smoke + 1]
    let cigarettes item index-smoke cigarette-list
    set smoking-rate cigarettes

    set discount (0.54 + random-float 0.46)
    set color white
    set shape "person"
    set size 0.6
    set inventory random 40

    ;; Wage initialization

    let random-number-wage random-float 1.0
    let index-wage 0
    while [index-wage < length wage-proportions-list - 1 and random-number-wage > item index-wage wage-proportions-list] [set index-wage index-wage + 1]
    set wage item index-wage wage-list
    set hourly-wage ( (wage / 52) / 40 )

    let rand random-float 1.0
    set transport-type (ifelse-value
        rand < t-car [ "car" ]
        rand < t-walk [ "walk" ]
        rand < t-bike [ "bike" ]
        [ "home" ]
        )
    if transport-type = "home" [ die ] ;; Tobacco Town paper does not model those that work from home
                                       ;; Proportions do not add up to 1

    (ifelse
        transport-type = "car" [set speed 21.2]
        transport-type = "walk" [set speed 2.1]
        transport-type = "bike" [set speed 7.5]
        )


    ;; Homes and work selection

    set smokers_home one-of home-nodes
    ask smokers_home [
      set color white
      set shape "house"
      set size 0.4
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

    ;; store neighbourhood type
    set my-neighbourhood neighbourhood
  ]

  ;; Initialise lists

  ask smokers with [my-neighbourhood = neighbourhood] [
  set total-distance-travelled []
  set total-cost-for-purchase []
  set total-cost-for-travel []
  set total-time-for-purchase []
  set total-cost-eq-per-pack []
  set list-retailer-type []
  set total-purchase-quantity []
  ]

end

;; generate smokers with everything random except homes, work and routes
to generate-smokers-V [t-wage-proportions t-car t-walk t-bike neighbourhood]

;;Smoking rate cumulative proportions
  set smoking-proportions-list [0.006 0.02 0.044 0.072 0.132 0.164 0.193 0.217 0.222 0.465 0.468 0.493 0.495 0.497 0.581 0.584 0.588 0.592 0.889 0.907 0.963 0.966 0.994 0.995 0.996 1.0]
  set cigarette-list [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 20 25 30 35 40 45 50 60]
  let home-nodes nobody
  let n-smokers 0
  (ifelse
    neighbourhood = "left" [
      set home-nodes nodes with [pxcor < max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "right" [
      set home-nodes nodes with [pxcor > max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "all" [
      set home-nodes nodes
      set n-smokers round ( population-density * ( world-width * world-height / 100 ))
    ]
  )

;; Wage Cumulative Proportions
  ;wage-proportions [0.078 0.154 0.318 0.452 0.632 0.786 0.892 0.966 0.991 1.0]
  set wage-proportions-list t-wage-proportions
  set wage-list [5000 12500 20000 30000 42500 62500 87500 125000 175000 250000]

  ;; create smokers with fixed home and work locations
  if random-spatial? = false [random-seed setup-seed]
  create-smokers (n-smokers) [
    ;; Homes and work selection
    set smokers_home one-of home-nodes
    ask smokers_home [
      set color white
      set shape "house"
      set size 0.4
      set is-a-home 1
    ]
    move-to smokers_home
    set work one-of nodes with [ is-a-workplace = 1 and distance myself > 0 ]
    ;; routes
    let s_work work
    let home_work_nodes 0
    ask smokers_home [
      set home_work_nodes nw:turtles-on-path-to s_work
    ]

    set commute_nodes turtle-set home_work_nodes      ;; Stores nodes on smokers commute

    ;; store neighbourhood type
    set my-neighbourhood neighbourhood
  ]

  ;; set smokers properties with random smoking rates and wages
  if random-spatial? = false [random-seed new-seed]
  ask smokers with [my-neighbourhood = neighbourhood] [
    ;; Smoking rate initialization
    let random-number-smoke random-float 1.0
    let index-smoke 0
    ifelse override-rates? = false [
      while [index-smoke < length smoking-proportions-list - 1 and random-number-smoke > item index-smoke smoking-proportions-list] [set index-smoke index-smoke + 1]
      let cigarettes item index-smoke cigarette-list
      set smoking-rate cigarettes
    ]
    ; if override-rates? = true
    [
      let smoking-rate-temp 0
      if neighbourhood = "left" [set smoking-rate-temp random-normal rates-mean-W rates-std-W]
      if neighbourhood = "right" [set smoking-rate-temp random-normal rates-mean-E rates-std-E]
      set smoking-rate max (list int smoking-rate-temp 0)
    ]

    set discount (0.54 + random-float 0.46)
    set color white
    set shape "person"
    set size 0.6
    set inventory random 40

    ;; Wage initialization
    let random-number-wage random-float 1.0
    let index-wage 0
    ifelse override-wages? = false [
      while [index-wage < length wage-proportions-list - 1 and random-number-wage > item index-wage wage-proportions-list] [set index-wage index-wage + 1]
      set wage item index-wage wage-list
      set hourly-wage ( (wage / 52) / 40 )
    ]
    ; if override-wages? = true
    [
      let wage-temp 0
      if neighbourhood = "left" [set wage-temp random-normal wages-mean-W wages-std-W]
      if neighbourhood = "right" [set wage-temp random-normal wages-mean-E wages-std-E]
      set wage max (list wage-temp 0)
      set hourly-wage ( (wage / 52) / 40 )
    ]

    let rand random-float 1.0
    set transport-type (ifelse-value
      rand < t-car [ "car" ]
      rand < t-walk [ "walk" ]
      rand < t-bike [ "bike" ]
      [ "home" ]
    )
    if transport-type = "home" [ die ] ;; Tobacco Town paper does not model those that work from home
                                       ;; Proportions do not add up to 1

    (ifelse
      transport-type = "car" [set speed 21.2]
      transport-type = "walk" [set speed 2.1]
      transport-type = "bike" [set speed 7.5]
    )

  ]

;; Initialise lists
  ask smokers with [my-neighbourhood = neighbourhood] [
  set total-distance-travelled []
  set total-cost-for-purchase []
  set total-cost-for-travel []
  set total-time-for-purchase []
  set total-cost-eq-per-pack []
  set list-retailer-type []
  set total-purchase-quantity []
  ]

  if random-spatial? = false [random-seed new-seed]

end

;; generate smokers with everything random except smoking rates, homes, work and routes
to generate-smokers-VC-rate [t-wage-proportions t-car t-walk t-bike neighbourhood]

;;Smoking rate cumulative proportions
  set smoking-proportions-list [0.006 0.02 0.044 0.072 0.132 0.164 0.193 0.217 0.222 0.465 0.468 0.493 0.495 0.497 0.581 0.584 0.588 0.592 0.889 0.907 0.963 0.966 0.994 0.995 0.996 1.0]
  set cigarette-list [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 20 25 30 35 40 45 50 60]
  let home-nodes nobody
  let n-smokers 0
  (ifelse
    neighbourhood = "left" [
      set home-nodes nodes with [pxcor < max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "right" [
      set home-nodes nodes with [pxcor > max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "all" [
      set home-nodes nodes
      set n-smokers round ( population-density * ( world-width * world-height / 100 ))
    ]
  )

;; Wage Cumulative Proportions
  ;wage-proportions [0.078 0.154 0.318 0.452 0.632 0.786 0.892 0.966 0.991 1.0]
  set wage-proportions-list t-wage-proportions
  set wage-list [5000 12500 20000 30000 42500 62500 87500 125000 175000 250000]

  ;; create smokers with fixed home and work locations
  if random-spatial? = false [random-seed setup-seed]
  create-smokers (n-smokers) [

    ;; Homes and work selection
    set smokers_home one-of home-nodes
    ask smokers_home [
      set color white
      set shape "house"
      set size 0.4
      set is-a-home 1
    ]
    move-to smokers_home
    set work one-of nodes with [ is-a-workplace = 1 and distance myself > 0 ]
    ;; routes
    let s_work work
    let home_work_nodes 0
    ask smokers_home [
      set home_work_nodes nw:turtles-on-path-to s_work
    ]
    set commute_nodes turtle-set home_work_nodes      ;; Stores nodes on smokers commute

    ;; store neighbourhood type
    set my-neighbourhood neighbourhood

  ]

  ;; fixed smoking rates
  ask smokers with [my-neighbourhood = neighbourhood] [
    ;; Smoking rate initialization
    let random-number-smoke random-float 1.0
    let index-smoke 0
    ifelse override-rates? = false [
      while [index-smoke < length smoking-proportions-list - 1 and random-number-smoke > item index-smoke smoking-proportions-list] [set index-smoke index-smoke + 1]
      let cigarettes item index-smoke cigarette-list
      set smoking-rate cigarettes
    ]
    ; if override-rates? = true
    [
      let smoking-rate-temp 0
      if neighbourhood = "left" [set smoking-rate-temp random-normal rates-mean-W rates-std-W]
      if neighbourhood = "right" [set smoking-rate-temp random-normal rates-mean-E rates-std-E]
      set smoking-rate max (list int smoking-rate-temp 0)
    ]
  ]

  ;; set smokers properties with everything random except smoking rates
  if random-spatial? = false [random-seed new-seed]
  ask smokers with [my-neighbourhood = neighbourhood] [
    ;; Discount
    set discount (0.54 + random-float 0.46)
    set color white
    set shape "person"
    set size 0.6

    ;; inventory
    set inventory random 40

    ;; Wage initialization
    let random-number-wage random-float 1.0
    let index-wage 0
    ifelse override-wages? = false [
      while [index-wage < length wage-proportions-list - 1 and random-number-wage > item index-wage wage-proportions-list] [set index-wage index-wage + 1]
      set wage item index-wage wage-list
      set hourly-wage ( (wage / 52) / 40 )
    ]
    ; if override-wages? = true
    [
      let wage-temp 0
      if neighbourhood = "left" [set wage-temp random-normal wages-mean-W wages-std-W]
      if neighbourhood = "right" [set wage-temp random-normal wages-mean-E wages-std-E]
      set wage max (list wage-temp 0)
      set hourly-wage ( (wage / 52) / 40 )
    ]

    ;; transport type
    let rand random-float 1.0
    set transport-type (ifelse-value
      rand < t-car [ "car" ]
      rand < t-walk [ "walk" ]
      rand < t-bike [ "bike" ]
      [ "home" ]
    )
    if transport-type = "home" [ die ] ;; Tobacco Town paper does not model those that work from home
                                       ;; Proportions do not add up to 1

    (ifelse
      transport-type = "car" [set speed 21.2]
      transport-type = "walk" [set speed 2.1]
      transport-type = "bike" [set speed 7.5]
    )
  ]


;; Initialise lists

  ask smokers [
  set total-distance-travelled []
  set total-cost-for-purchase []
  set total-cost-for-travel []
  set total-time-for-purchase []
  set total-cost-eq-per-pack []
  set list-retailer-type []
  set total-purchase-quantity []
  ]

  if random-spatial? = false [random-seed new-seed]

end

;; generate smokers with everything random except inventory, homes, work and routes
to generate-smokers-VC-inventory [t-wage-proportions t-car t-walk t-bike neighbourhood]

;;Smoking rate cumulative proportions
  set smoking-proportions-list [0.006 0.02 0.044 0.072 0.132 0.164 0.193 0.217 0.222 0.465 0.468 0.493 0.495 0.497 0.581 0.584 0.588 0.592 0.889 0.907 0.963 0.966 0.994 0.995 0.996 1.0]
  set cigarette-list [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 20 25 30 35 40 45 50 60]
  let home-nodes nobody
  let n-smokers 0
  (ifelse
    neighbourhood = "left" [
      set home-nodes nodes with [pxcor < max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "right" [
      set home-nodes nodes with [pxcor > max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "all" [
      set home-nodes nodes
      set n-smokers round ( population-density * ( world-width * world-height / 100 ))
    ]
  )

;; Wage Cumulative Proportions
  ;wage-proportions [0.078 0.154 0.318 0.452 0.632 0.786 0.892 0.966 0.991 1.0]
  set wage-proportions-list t-wage-proportions
  set wage-list [5000 12500 20000 30000 42500 62500 87500 125000 175000 250000]

  ;; create smokers with fixed home and work locations
  if random-spatial? = false [random-seed setup-seed]
  create-smokers (n-smokers) [

    ;; Homes and work selection
    set smokers_home one-of home-nodes
    ask smokers_home [
      set color white
      set shape "house"
      set size 0.4
      set is-a-home 1
    ]
    move-to smokers_home
    set work one-of nodes with [ is-a-workplace = 1 and distance myself > 0 ]
    ;; routes
    let s_work work
    let home_work_nodes 0
    ask smokers_home [
      set home_work_nodes nw:turtles-on-path-to s_work
    ]
    set commute_nodes turtle-set home_work_nodes      ;; Stores nodes on smokers commute

    ;; store neighbourhood type
    set my-neighbourhood neighbourhood


  ]

  ;; fixed inventory
  ask smokers with [my-neighbourhood = neighbourhood] [
    ;; inventory
    set color white
    set shape "person"
    set size 0.6
    set inventory random 40
  ]

  ;; set smokers properties with everything random except smoking rates
  if random-spatial? = false [random-seed new-seed]
  ask smokers with [my-neighbourhood = neighbourhood] [
    ;; discount
    set discount (0.54 + random-float 0.46)

    ;; Smoking rate initialization
    let random-number-smoke random-float 1.0
    let index-smoke 0
    ifelse override-rates? = false [
      while [index-smoke < length smoking-proportions-list - 1 and random-number-smoke > item index-smoke smoking-proportions-list] [set index-smoke index-smoke + 1]
      let cigarettes item index-smoke cigarette-list
      set smoking-rate cigarettes
    ]
    ; if override-rates? = true
    [
      let smoking-rate-temp 0
      if neighbourhood = "left" [set smoking-rate-temp random-normal rates-mean-W rates-std-W]
      if neighbourhood = "right" [set smoking-rate-temp random-normal rates-mean-E rates-std-E]
      set smoking-rate max (list int smoking-rate-temp 0)
    ]

    ;; Wage initialization
    let random-number-wage random-float 1.0
    let index-wage 0
    ifelse override-wages? = false [
      while [index-wage < length wage-proportions-list - 1 and random-number-wage > item index-wage wage-proportions-list] [set index-wage index-wage + 1]
      set wage item index-wage wage-list
      set hourly-wage ( (wage / 52) / 40 )
    ]
    ; if override-wages? = true
    [
      let wage-temp 0
      if neighbourhood = "left" [set wage-temp random-normal wages-mean-W wages-std-W]
      if neighbourhood = "right" [set wage-temp random-normal wages-mean-E wages-std-E]
      set wage max (list wage-temp 0)
      set hourly-wage ( (wage / 52) / 40 )
    ]

    let rand random-float 1.0
    set transport-type (ifelse-value
      rand < t-car [ "car" ]
      rand < t-walk [ "walk" ]
      rand < t-bike [ "bike" ]
      [ "home" ]
    )
    if transport-type = "home" [ die ] ;; Tobacco Town paper does not model those that work from home
                                       ;; Proportions do not add up to 1

    (ifelse
      transport-type = "car" [set speed 21.2]
      transport-type = "walk" [set speed 2.1]
      transport-type = "bike" [set speed 7.5]
    )
  ]

;; Initialise lists
  ask smokers with [my-neighbourhood = neighbourhood] [
  set total-distance-travelled []
  set total-cost-for-purchase []
  set total-cost-for-travel []
  set total-time-for-purchase []
  set total-cost-eq-per-pack []
  set list-retailer-type []
  set total-purchase-quantity []
  ]

  if random-spatial? = false [random-seed new-seed]

end

;; generate smokers with everything random except wages, homes, work and routes
to generate-smokers-VC-wage [t-wage-proportions t-car t-walk t-bike neighbourhood]

;;Smoking rate cumulative proportions
  set smoking-proportions-list [0.006 0.02 0.044 0.072 0.132 0.164 0.193 0.217 0.222 0.465 0.468 0.493 0.495 0.497 0.581 0.584 0.588 0.592 0.889 0.907 0.963 0.966 0.994 0.995 0.996 1.0]
  set cigarette-list [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 20 25 30 35 40 45 50 60]
  let home-nodes nobody
  let n-smokers 0
  (ifelse
    neighbourhood = "left" [
      set home-nodes nodes with [pxcor < max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "right" [
      set home-nodes nodes with [pxcor > max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "all" [
      set home-nodes nodes
      set n-smokers round ( population-density * ( world-width * world-height / 100 ))
    ]
  )

;; Wage Cumulative Proportions
  ;wage-proportions [0.078 0.154 0.318 0.452 0.632 0.786 0.892 0.966 0.991 1.0]
  set wage-proportions-list t-wage-proportions
  set wage-list [5000 12500 20000 30000 42500 62500 87500 125000 175000 250000]

  ;; create smokers with fixed home and work locations
  if random-spatial? = false [random-seed setup-seed]
  create-smokers (n-smokers) [

    ;; Homes and work selection
    set smokers_home one-of home-nodes
    ask smokers_home [
      set color white
      set shape "house"
      set size 0.4
      set is-a-home 1
    ]
    move-to smokers_home
    set work one-of nodes with [ is-a-workplace = 1 and distance myself > 0 ]
    ;; routes
    let s_work work
    let home_work_nodes 0
    ask smokers_home [
      set home_work_nodes nw:turtles-on-path-to s_work
    ]
    set commute_nodes turtle-set home_work_nodes      ;; Stores nodes on smokers commute

    ;; store neighbourhood type
    set my-neighbourhood neighbourhood
  ]

  ;; fixed wages
  ask smokers with [my-neighbourhood = neighbourhood] [
    ;; Wage initialization
    let random-number-wage random-float 1.0
    let index-wage 0
    ifelse override-wages? = false [
      while [index-wage < length wage-proportions-list - 1 and random-number-wage > item index-wage wage-proportions-list] [set index-wage index-wage + 1]
      set wage item index-wage wage-list
      set hourly-wage ( (wage / 52) / 40 )
    ]
    ; if override-wages? = true
    [
      let wage-temp 0
      if neighbourhood = "left" [set wage-temp random-normal wages-mean-W wages-std-W]
      if neighbourhood = "right" [set wage-temp random-normal wages-mean-E wages-std-E]
      set wage max (list wage-temp 0)
      set hourly-wage ( (wage / 52) / 40 )
    ]
  ]

  ;; set smokers properties with everything random except wages
  if random-spatial? = false [random-seed new-seed]
  ask smokers with [my-neighbourhood = neighbourhood] [
    ;; Discount
    set discount (0.54 + random-float 0.46)
    set color white
    set shape "person"
    set size 0.6

    ;; inventory
    set inventory random 40

    ;; Smoking rate initialization
    let random-number-smoke random-float 1.0
    let index-smoke 0
    ifelse override-rates? = false [
      while [index-smoke < length smoking-proportions-list - 1 and random-number-smoke > item index-smoke smoking-proportions-list] [set index-smoke index-smoke + 1]
      let cigarettes item index-smoke cigarette-list
      set smoking-rate cigarettes
    ]
    ; if override-rates? = true
    [
      let smoking-rate-temp 0
      if neighbourhood = "left" [set smoking-rate-temp random-normal rates-mean-W rates-std-W]
      if neighbourhood = "right" [set smoking-rate-temp random-normal rates-mean-E rates-std-E]
      set smoking-rate max (list int smoking-rate-temp 0)
    ]

    ;; transport type
    let rand random-float 1.0
    set transport-type (ifelse-value
      rand < t-car [ "car" ]
      rand < t-walk [ "walk" ]
      rand < t-bike [ "bike" ]
      [ "home" ]
    )
    if transport-type = "home" [ die ] ;; Tobacco Town paper does not model those that work from home
                                       ;; Proportions do not add up to 1

    (ifelse
      transport-type = "car" [set speed 21.2]
      transport-type = "walk" [set speed 2.1]
      transport-type = "bike" [set speed 7.5]
    )
  ]


;; Initialise lists

  ask smokers with [my-neighbourhood = neighbourhood] [
  set total-distance-travelled []
  set total-cost-for-purchase []
  set total-cost-for-travel []
  set total-time-for-purchase []
  set total-cost-eq-per-pack []
  set list-retailer-type []
  set total-purchase-quantity []
  ]

  if random-spatial? = false [random-seed new-seed]

end

;; generate smokers with everything random except transport types, homes, work and routes
to generate-smokers-VC-transport [t-wage-proportions t-car t-walk t-bike neighbourhood]

;;Smoking rate cumulative proportions
  set smoking-proportions-list [0.006 0.02 0.044 0.072 0.132 0.164 0.193 0.217 0.222 0.465 0.468 0.493 0.495 0.497 0.581 0.584 0.588 0.592 0.889 0.907 0.963 0.966 0.994 0.995 0.996 1.0]
  set cigarette-list [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 20 25 30 35 40 45 50 60]
  let home-nodes nobody
  let n-smokers 0
  (ifelse
    neighbourhood = "left" [
      set home-nodes nodes with [pxcor < max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "right" [
      set home-nodes nodes with [pxcor > max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "all" [
      set home-nodes nodes
      set n-smokers round ( population-density * ( world-width * world-height / 100 ))
    ]
  )

;; Wage Cumulative Proportions
  ;wage-proportions [0.078 0.154 0.318 0.452 0.632 0.786 0.892 0.966 0.991 1.0]
  set wage-proportions-list t-wage-proportions
  set wage-list [5000 12500 20000 30000 42500 62500 87500 125000 175000 250000]

  ;; create smokers with fixed home and work locations
  if random-spatial? = false [random-seed setup-seed]
  create-smokers (n-smokers) [

    ;; Homes and work selection
    set smokers_home one-of home-nodes
    ask smokers_home [
      set color white
      set shape "house"
      set size 0.4
      set is-a-home 1
    ]
    move-to smokers_home
    set work one-of nodes with [ is-a-workplace = 1 and distance myself > 0 ]
    ;; routes
    let s_work work
    let home_work_nodes 0
    ask smokers_home [
      set home_work_nodes nw:turtles-on-path-to s_work
    ]
    set commute_nodes turtle-set home_work_nodes      ;; Stores nodes on smokers commute

    ;; store neighbourhood type
    set my-neighbourhood neighbourhood
  ]

  ;; fixed smoking rates
  ask smokers with [my-neighbourhood = neighbourhood] [
    ;; transport type
    let rand random-float 1.0
    set transport-type (ifelse-value
      rand < t-car [ "car" ]
      rand < t-walk [ "walk" ]
      rand < t-bike [ "bike" ]
      [ "home" ]
    )
    if transport-type = "home" [ die ] ;; Tobacco Town paper does not model those that work from home
                                       ;; Proportions do not add up to 1
  ]

  ;; set smokers properties with everything random except smoking rates
  if random-spatial? = false [random-seed new-seed]
  ask smokers with [my-neighbourhood = neighbourhood] with [my-neighbourhood = neighbourhood] [
    ;; Discount
    set discount (0.54 + random-float 0.46)
    set color white
    set shape "person"
    set size 0.6

    ;; inventory
    set inventory random 40

    ;; Smoking rate initialization
    let random-number-smoke random-float 1.0
    let index-smoke 0
    ifelse override-rates? = false [
      while [index-smoke < length smoking-proportions-list - 1 and random-number-smoke > item index-smoke smoking-proportions-list] [set index-smoke index-smoke + 1]
      let cigarettes item index-smoke cigarette-list
      set smoking-rate cigarettes
    ]
    ; if override-rates? = true
    [
      let smoking-rate-temp 0
      if neighbourhood = "left" [set smoking-rate-temp random-normal rates-mean-W rates-std-W]
      if neighbourhood = "right" [set smoking-rate-temp random-normal rates-mean-E rates-std-E]
      set smoking-rate max (list int smoking-rate-temp 0)
    ]

    ;; Wage initialization
    let random-number-wage random-float 1.0
    let index-wage 0
    ifelse override-wages? = false [
      while [index-wage < length wage-proportions-list - 1 and random-number-wage > item index-wage wage-proportions-list] [set index-wage index-wage + 1]
      set wage item index-wage wage-list
      set hourly-wage ( (wage / 52) / 40 )
    ]
    ; if override-wages? = true
    [
      let wage-temp 0
      if neighbourhood = "left" [set wage-temp random-normal wages-mean-W wages-std-W]
      if neighbourhood = "right" [set wage-temp random-normal wages-mean-E wages-std-E]
      set wage max (list wage-temp 0)
      set hourly-wage ( (wage / 52) / 40 )
    ]

    (ifelse
      transport-type = "car" [set speed 21.2]
      transport-type = "walk" [set speed 2.1]
      transport-type = "bike" [set speed 7.5]
    )
  ]


;; Initialise lists

  ask smokers with [my-neighbourhood = neighbourhood] [
  set total-distance-travelled []
  set total-cost-for-purchase []
  set total-cost-for-travel []
  set total-time-for-purchase []
  set total-cost-eq-per-pack []
  set list-retailer-type []
  set total-purchase-quantity []
  ]

  if random-spatial? = false [random-seed new-seed]

end

;; generate smokers with everything random except homes and work (routes are random)
to generate-smokers-V-routes [t-wage-proportions t-car t-walk t-bike neighbourhood]

;;Smoking rate cumulative proportions
  set smoking-proportions-list [0.006 0.02 0.044 0.072 0.132 0.164 0.193 0.217 0.222 0.465 0.468 0.493 0.495 0.497 0.581 0.584 0.588 0.592 0.889 0.907 0.963 0.966 0.994 0.995 0.996 1.0]
  set cigarette-list [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 20 25 30 35 40 45 50 60]
  let home-nodes nobody
  let n-smokers 0
  (ifelse
    neighbourhood = "left" [
      set home-nodes nodes with [pxcor < max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "right" [
      set home-nodes nodes with [pxcor > max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "all" [
      set home-nodes nodes
      set n-smokers round ( population-density * ( world-width * world-height / 100 ))
    ]
  )

;; Wage Cumulative Proportions
  ;wage-proportions [0.078 0.154 0.318 0.452 0.632 0.786 0.892 0.966 0.991 1.0]
  set wage-proportions-list t-wage-proportions
  set wage-list [5000 12500 20000 30000 42500 62500 87500 125000 175000 250000]

  ;; create smokers with fixed home and work locations
  if random-spatial? = false [random-seed setup-seed]
  create-smokers (n-smokers) [
    ;; Homes and work selection
    set smokers_home one-of home-nodes
    ask smokers_home [
      set color white
      set shape "house"
      set size 0.4
      set is-a-home 1
    ]
    move-to smokers_home
    set work one-of nodes with [ is-a-workplace = 1 and distance myself > 0 ]
    ;; routes
    let s_work work
    let home_work_nodes 0
    ask smokers_home [
      set home_work_nodes nw:turtles-on-path-to s_work
    ]
    set commute_nodes turtle-set home_work_nodes      ;; Stores nodes on smokers commute

    ;; store neighbourhood type
    set my-neighbourhood neighbourhood
  ]

  ;; random everything
  if random-spatial? = false [random-seed new-seed]
  ask smokers with [my-neighbourhood = neighbourhood] [
    ;; routes
    let s_work work
    let home_work_nodes 0
    ask smokers_home [
      set home_work_nodes nw:turtles-on-path-to s_work
    ]
    set commute_nodes turtle-set home_work_nodes      ;; Stores nodes on smokers commute

    ;; Smoking rate initialization
    let random-number-smoke random-float 1.0
    let index-smoke 0
    ifelse override-rates? = false [
      while [index-smoke < length smoking-proportions-list - 1 and random-number-smoke > item index-smoke smoking-proportions-list] [set index-smoke index-smoke + 1]
      let cigarettes item index-smoke cigarette-list
      set smoking-rate cigarettes
    ]
    ; if override-rates? = true
    [
      let smoking-rate-temp 0
      if neighbourhood = "left" [set smoking-rate-temp random-normal rates-mean-W rates-std-W]
      if neighbourhood = "right" [set smoking-rate-temp random-normal rates-mean-E rates-std-E]
      set smoking-rate max (list int smoking-rate-temp 0)
    ]

    set discount (0.54 + random-float 0.46)
    set color white
    set shape "person"
    set size 0.6
    set inventory random 40

    ;; Wage initialization
    let random-number-wage random-float 1.0
    let index-wage 0
    ifelse override-wages? = false [
      while [index-wage < length wage-proportions-list - 1 and random-number-wage > item index-wage wage-proportions-list] [set index-wage index-wage + 1]
      set wage item index-wage wage-list
      set hourly-wage ( (wage / 52) / 40 )
    ]
    ; if override-wages? = true
    [
      let wage-temp 0
      if neighbourhood = "left" [set wage-temp random-normal wages-mean-W wages-std-W]
      if neighbourhood = "right" [set wage-temp random-normal wages-mean-E wages-std-E]
      set wage max (list wage-temp 0)
      set hourly-wage ( (wage / 52) / 40 )
    ]

    let rand random-float 1.0
    set transport-type (ifelse-value
      rand < t-car [ "car" ]
      rand < t-walk [ "walk" ]
      rand < t-bike [ "bike" ]
      [ "home" ]
    )
    if transport-type = "home" [ die ] ;; Tobacco Town paper does not model those that work from home
                                       ;; Proportions do not add up to 1

    (ifelse
      transport-type = "car" [set speed 21.2]
      transport-type = "walk" [set speed 2.1]
      transport-type = "bike" [set speed 7.5]
    )

  ]

;; Initialise lists
  ask smokers with [my-neighbourhood = neighbourhood] [
  set total-distance-travelled []
  set total-cost-for-purchase []
  set total-cost-for-travel []
  set total-time-for-purchase []
  set total-cost-eq-per-pack []
  set list-retailer-type []
  set total-purchase-quantity []
  ]

  if random-spatial? = false [random-seed new-seed]

end

;; generate smokers with everything random except smoking routes
to generate-smokers-VC-routes [t-wage-proportions t-car t-walk t-bike neighbourhood]

;;Smoking rate cumulative proportions
  set smoking-proportions-list [0.006 0.02 0.044 0.072 0.132 0.164 0.193 0.217 0.222 0.465 0.468 0.493 0.495 0.497 0.581 0.584 0.588 0.592 0.889 0.907 0.963 0.966 0.994 0.995 0.996 1.0]
  set cigarette-list [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 20 25 30 35 40 45 50 60]
  let home-nodes nobody
  let n-smokers 0
  (ifelse
    neighbourhood = "left" [
      set home-nodes nodes with [pxcor < max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "right" [
      set home-nodes nodes with [pxcor > max-pxcor / 2]
      set n-smokers round ( population-density * ( world-width * world-height / 200 ))
    ]
    neighbourhood = "all" [
      set home-nodes nodes
      set n-smokers round ( population-density * ( world-width * world-height / 100 ))
    ]
  )

;; Wage Cumulative Proportions
  ;wage-proportions [0.078 0.154 0.318 0.452 0.632 0.786 0.892 0.966 0.991 1.0]
  set wage-proportions-list t-wage-proportions
  set wage-list [5000 12500 20000 30000 42500 62500 87500 125000 175000 250000]


  ;; create smokers with fixed home and work locations
  if random-spatial? = false [random-seed setup-seed]
  create-smokers (n-smokers) [
    ;; Homes and work selection
    set smokers_home one-of home-nodes
    ask smokers_home [
      set color white
      set shape "house"
      set size 0.4
      set is-a-home 1
    ]
    move-to smokers_home
    set work one-of nodes with [ is-a-workplace = 1 and distance myself > 0 ]
    ;; routes
    let s_work work
    let home_work_nodes 0
    ask smokers_home [
      set home_work_nodes nw:turtles-on-path-to s_work
    ]
    set commute_nodes turtle-set home_work_nodes      ;; Stores nodes on smokers commute

    ;; store neighbourhood type
    set my-neighbourhood neighbourhood
  ]

  ;; everything random except routes
  if random-spatial? = false [random-seed new-seed]
  ask smokers with [my-neighbourhood = neighbourhood] [
    ;; Smoking rate initialization
    let random-number-smoke random-float 1.0
    let index-smoke 0
    ifelse override-rates? = false [
      while [index-smoke < length smoking-proportions-list - 1 and random-number-smoke > item index-smoke smoking-proportions-list] [set index-smoke index-smoke + 1]
      let cigarettes item index-smoke cigarette-list
      set smoking-rate cigarettes
    ]
    ; if override-rates? = true
    [
      let smoking-rate-temp 0
      if neighbourhood = "left" [set smoking-rate-temp random-normal rates-mean-W rates-std-W]
      if neighbourhood = "right" [set smoking-rate-temp random-normal rates-mean-E rates-std-E]
      set smoking-rate max (list int smoking-rate-temp 0)
    ]

    ;; Discount and inventory
    set discount (0.54 + random-float 0.46)
    set color white
    set shape "person"
    set size 0.6
    set inventory random 40

    ;; Wage initialization
    let random-number-wage random-float 1.0
    let index-wage 0
    ifelse override-wages? = false [
      while [index-wage < length wage-proportions-list - 1 and random-number-wage > item index-wage wage-proportions-list] [set index-wage index-wage + 1]
      set wage item index-wage wage-list
      set hourly-wage ( (wage / 52) / 40 )
    ]
    ; if override-wages? = true
    [
      let wage-temp 0
      if neighbourhood = "left" [set wage-temp random-normal wages-mean-W wages-std-W]
      if neighbourhood = "right" [set wage-temp random-normal wages-mean-E wages-std-E]
      set wage max (list wage-temp 0)
      set hourly-wage ( (wage / 52) / 40 )
    ]

    let rand random-float 1.0
    set transport-type (ifelse-value
      rand < t-car [ "car" ]
      rand < t-walk [ "walk" ]
      rand < t-bike [ "bike" ]
      [ "home" ]
    )
    if transport-type = "home" [ die ] ;; Tobacco Town paper does not model those that work from home
                                       ;; Proportions do not add up to 1

    (ifelse
      transport-type = "car" [set speed 21.2]
      transport-type = "walk" [set speed 2.1]
      transport-type = "bike" [set speed 7.5]
    )
  ]

;; Initialise lists
  ask smokers with [my-neighbourhood = neighbourhood] [
  set total-distance-travelled []
  set total-cost-for-purchase []
  set total-cost-for-travel []
  set total-time-for-purchase []
  set total-cost-eq-per-pack []
  set list-retailer-type []
  set total-purchase-quantity []
  ]

  if random-spatial? = false [random-seed new-seed]

end

to generate-outlet-type [ t-name t-color t-prop  t-dist-l t-dist-m t-dist-r  neighbourhood]
  ;; find the neighbourhood nodes (left or right or all the space) and calculate the number of outlets to create
  let neighbourhood-nodes nobody
  let n-outlets 0
  (ifelse
    neighbourhood = "left" [
      set neighbourhood-nodes nodes with [xcor < max-pxcor / 2]
      set n-outlets round ( (world-width * world-height / 200 ) * random-normal t-prop 0.5 )
    ]
    neighbourhood = "right" [
      set neighbourhood-nodes nodes with [xcor > max-pxcor / 2]
      set n-outlets round ( (world-width * world-height / 200 ) * random-normal t-prop 0.5 )
    ]
    neighbourhood = "all" [
      set neighbourhood-nodes nodes
      set n-outlets round ( (world-width * world-height / 100 ) * random-normal t-prop 0.5 )
    ]
  )

  create-outlets ( n-outlets ) [            ;; Random-normal applies Normal Distribtion to retailer densities
    set outlet-type t-name
    set color t-color
    set shape "target"
    set size 0.4
    set price price-normal-dist t-dist-l t-dist-m t-dist-r
    set outlet_place one-of neighbourhood-nodes with [ is-an-outlet = 0 ]
    set outlet_place one-of neighbourhood-nodes with [ is-an-outlet = 0 ]
    ask outlet_place [
      set is-an-outlet 1
    ]
    move-to outlet_place
  ]

end

to generate-schools [density neighbourhood]
  ;; find the neighbourhood nodes (left or right or all the space) and calculate the number of schools to create
  let neighbourhood-nodes nobody
  let n-schools 0
  (ifelse
    neighbourhood = "left" [
      set neighbourhood-nodes nodes with [xcor < max-pxcor / 2]
      if density > ( (count neighbourhood-nodes) / ( world-width * world-height / 200 ) ) [ set density ( (count neighbourhood-nodes) / ( world-width * world-height / 200 ) ) ] ;; If workplace density saturates nodes then workplace-density is set to node-density
      set n-schools round ( (world-width * world-height / 200 ) * density )
    ]
    neighbourhood = "right" [
      set neighbourhood-nodes nodes with [xcor > max-pxcor / 2]
      if density > ( (count neighbourhood-nodes) / ( world-width * world-height / 200 ) ) [ set density ( (count neighbourhood-nodes) / ( world-width * world-height / 200 ) ) ] ;; If workplace density saturates nodes then workplace-density is set to node-density
      set n-schools round ( (world-width * world-height / 200 ) * density )
    ]
    neighbourhood = "all" [
      set neighbourhood-nodes nodes
      if density > ( (count neighbourhood-nodes) / ( world-width * world-height / 100 ) ) [ set density ( (count neighbourhood-nodes) / ( world-width * world-height / 100 ) ) ] ;; If workplace density saturates nodes then workplace-density is set to node-density
      set n-schools round ( (world-width * world-height / 100 ) * density )
    ]
  )
  ;; create the schools
  create-schools ( n-schools )  [
    set color 55
    set shape "tree"
    set size 0.4
    move-to one-of neighbourhood-nodes
  ]
end

to-report price-normal-dist [mid dev mmin]  ;; Creates truncated normal distribution for tobacco price
  let result random-normal mid dev
  if result < mmin
    [ report price-normal-dist mid dev mmin ]
  report result
end

to set-fuel-price
  ask smokers [
    (ifelse
      transport-type = "car"
      [set fuel-price 3.01]
      [set fuel-price 0 ]
      )
  ]
end

to run-fast
  if day = 0 [reset-timer]
  ;print "Start run"
  if day = number-of-days [
    report-end-state
    ;print timer
    visualise
    stop
  ]

  ;write "asking smokers" type "\n"
  ask smokers [
    set color white
    set inventory ( inventory - smoking-rate )
    if inventory < smoking-rate [
      ;write "*"
      purchase
    ]
  ]
  ;print ""

  tick
  set day (day + 1)
  ;print day
end

; smoker agent procedure
to purchase
  set color red
  find-optimum-path
  get-costs
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

; smoker agent procedure
to find-optimum-path
  ;; this will find the outlet that is best on way to work

  let s_list []
  calc-price
  set s_list sort-by [ [?1 ?2 ] -> get-best-price  ?1  < get-best-price  ?2  ] outlet_index

;; Trembling hand - there is a probability of 0.025 that the optimum retailer is not chosen (procedure below)
  let index_no 0
  ;; 0.025 = Probability that the best retailer isn't chosen
  ifelse random-float 1 > 0.025 [
    set index_no item 0  s_list
  ]
  ;; 1 - 0.025 = Probability that the best retailer is chosen
  [

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

; smoker agent proocedure
to calc-price
  let cost-at-r 0
  let calc 0
  let s_commute_nodes commute_nodes
  ;; YG Discount is a smoker parameter generated at initialisation
  let c_discount discount
  let c_speed speed
  let c_hourly-wage hourly-wage
  ;; YG Inventory is the number of cigarettes currently owned
  let c_inventory inventory
  let c_smoking-rate smoking-rate
  let c_transport-type transport-type
  let c_fuel-price fuel-price


  ask  outlets [
    ;; YG this is called for every outlet every day although the path to the house and the outlets remain the same across the simulation
    let nearest-node min-one-of s_commute_nodes [ distance myself ]
    let off_path 0
    ask outlet_place [
      set off_path nw:distance-to nearest-node
    ]
    ; YG why is off_path divided by 5 here?
    set difference (off_path / 5)
    ;; More efficient algorithm (steepest-descent hill climbing algorithm)
    let quantity 1
    let quantity-tens 10      ;; quantities at increments of 10 (divisible by 10)
    set current-q quantity
    let current-value 99999
    let min-value 99999
    ;; calculate prices and increment `quantity` as relevant
    ;; condition forces loop to end if increasing the `quantity` leads to an increase in price
    while [min-value = current-value] [
      ;; identify current price and modify it if the quantity is divisible by 10
      let c_price price
      if quantity mod 10 = 0 and buy-cartons? = true [ set c_price ( ( price * 7.63 ) / 10 ) ]
      ;; Generates a list of values from 1 to q eg [ 1 2 3 4 5 6] for q=6
      let qq-list n-values quantity [x -> x + 1]
      ;; Separates complicated sum function from main equation
      let sum-function sum (map [ x -> c_discount ^ (floor ((20 * (x - 1) + c_inventory) / c_smoking-rate)) ] qq-list)
      ;; main equation
      set current-value (  ((( difference / c_speed + 1 / 12) * c_hourly-wage * vl + difference * c_fuel-price / efficiency + quantity * c_price ) / sum-function ))

      ;; If newest value is lower, min-value is updated and current-q is recorded
      ifelse current-value < min-value [
        set min-value current-value
        set current-q quantity
        set cost-at-r   (( difference / c_speed + 1 / 12) * c_hourly-wage * vl + difference * c_fuel-price / efficiency + current-q * c_price ) / current-q

      ]
      ;; If the newest value is higher, skip to the next 10s quantity (`quantity-tens`) and check if the price at `quantity-tens` is lower than the price at `quantity`
      ;; Note: we skipt to the next `quantity-tens` because packs of 10s are expected to have lower prices in general
      [
        if buy-cartons? = true [set c_price ( ( price * 7.63 ) / 10 )]
        set qq-list n-values quantity-tens [x -> x + 1]
        set sum-function sum (map [ x -> c_discount ^ (floor ((20 * (x - 1) + c_inventory) / c_smoking-rate)) ] qq-list)
        let current-value-tens (  ((( difference / c_speed + 1 / 12) * c_hourly-wage * vl + difference * c_fuel-price / efficiency + quantity-tens * c_price ) / sum-function ))
        ;; If newest value of the pack is lower, min-value is updated and current-q is recorded
        if current-value-tens < min-value [
          set current-value current-value-tens
          set min-value current-value
          set current-q quantity-tens
          set cost-at-r   (( difference / c_speed + 1 / 12) * c_hourly-wage * vl + difference * c_fuel-price / efficiency + current-q * c_price ) / current-q
          ;; quantity is updated to quantity-tens so that the next loop will check quantity-tens + 1 (i.e., 11 or 21 or 31... etc.)
          set quantity quantity-tens
        ]
      ]
      ;; increment `quantity` by 1
      set quantity quantity + 1
      ;; increment `quantity-tens` by 10 if the `quantity` exceeded it
      if quantity >= quantity-tens [set quantity-tens quantity-tens + 10]
    ]
    set best-price cost-at-r
    set best-quantity current-q

  ] ;; outlets loop

end

; smoker agent procedures
to get-costs
  set pack-price [price] of nearest_outlet
  set retailer-type [outlet-type] of nearest_outlet
  set distance-for-purchase [difference] of nearest_outlet
  set packs-purchased [best-quantity] of nearest_outlet
  if packs-purchased mod 10 = 0 [ set pack-price ( (pack-price * 7.63 ) / 10 ) ]
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
    school-buffer = "500 Feet" [ 1 ] ;; 1 is the patch distance
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


ask outlets
  [ if outlet-type = retailer-removal [
    ask outlet_place [ set is-an-outlet 0 ]
    die
    ]
  ]

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

to visualise
  ;; patches
  (
    ifelse
    visualise-mode-patches = "Smokers avg. purchase cost" [
      ask turtles [hide-turtle]
      ask patches with [count smokers-here > 0] [
        set smokers-median-cost median [smoker-average-purchase-cost] of smokers-here
        set smokers-median-quantity median [smoker-average-purchase-quantity] of smokers-here
        set smokers-median-wage median [wage] of smokers-here
      ]
      ask patches with [count smokers-here > 0] [set pcolor scale-color red smokers-median-cost (max [smokers-median-cost] of patches) (min [smokers-median-cost] of patches)]
    ]
    visualise-mode-patches = "Smokers avg. purchase quantity" [
      ask turtles [hide-turtle]
      ask patches with [count smokers-here > 0] [
        set smokers-median-cost median [smoker-average-purchase-cost] of smokers-here
        set smokers-median-quantity median [smoker-average-purchase-quantity] of smokers-here
        set smokers-median-wage median [wage] of smokers-here
      ]
      ask patches with [count smokers-here > 0] [set pcolor scale-color red smokers-median-quantity (max [smokers-median-quantity] of patches) (min [smokers-median-quantity] of patches)]
    ]
    visualise-mode-patches = "Route length" [
      ask turtles [hide-turtle]
      ask patches [set pcolor white]
      ask links [hide-link]
      ask patches with [count smokers-here > 0] [
        set smokers-median-route median [count commute_nodes] of smokers-here
      ]
      ask patches with [count smokers-here > 0] [set pcolor scale-color red smokers-median-route (max [smokers-median-route] of patches) (min [smokers-median-route] of patches)]
    ]
    visualise-mode-patches = "None" [
      ask patches [set pcolor black]
    ]
  )

  ;; agents
  (
    ifelse
    visualise-mode-turtles = "All agents" [
      ask turtles [show-turtle]
      ask smokers [set size 0.6]
    ]
    visualise-mode-turtles = "Smokers only" [
      ask turtles [hide-turtle]
      ask smokers [
        show-turtle
        set size 1
      ]
    ]
    visualise-mode-turtles = "None" [
      ask turtles [hide-turtle]
    ]
  )

end

;; only called in behaviour space runs
to update-globals
  report-end-state
  ask patches with [count smokers-here > 0] [
    set smokers-median-cost median [smoker-average-purchase-cost] of smokers-here
    set smokers-median-quantity median [smoker-average-purchase-quantity] of smokers-here
    set smokers-median-wage median [wage] of smokers-here
    set smokers-median-rate median [smoking-rate] of smokers-here
  ]
  set median-quantity map [p -> [(list pxcor pycor smokers-median-quantity)] of p] (sort patches)
  set median-cost map [p -> [(list pxcor pycor smokers-median-cost)] of p] (sort patches)
  set median-wage map [p -> [(list pxcor pycor smokers-median-wage)] of p] (sort patches)
  set median-rate map [p -> [(list pxcor pycor smokers-median-rate)] of p] (sort patches)
end
@#$#@#$#@
GRAPHICS-WINDOW
262
29
656
424
-1
-1
12.063
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
167
70
200
NIL
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
8
34
247
79
town-type
town-type
"Suburban Poor" "Suburban Rich" "Urban Poor" "Urban Rich" "Urban Poor | Urban Rich" "Urban Poor (no work or outlets) | Urban Rich" "Controlled | Controlled"
3

MONITOR
675
10
877
55
Population Density (per square mile)
count smokers / ((world-height * world-width) / 100 )
1
1
11

PLOT
673
266
1079
416
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
"default" 1.0 1 -16777216 true "" "histogram [smoking-rate] of smokers set-histogram-num-bars 100"

PLOT
675
106
1077
256
Wage Distribution
Wage ($)
Count
0.0
250000.0
0.0
3.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [wage] of smokers set-histogram-num-bars 100"

MONITOR
887
11
1089
56
Total Retailer Density (per sqaure mile)
count outlets / (world-height * world-width / 100)
1
1
11

MONITOR
675
59
877
104
School Density (per square mile)
count schools / (world-width * world-height / 100 )
1
1
11

MONITOR
500
496
593
541
NIL
mode
17
1
11

SLIDER
6
367
178
400
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
7
404
145
449
school-buffer
school-buffer
"None" "500 Feet" "1000 Feet" "1500 Feet"
0

CHOOSER
8
453
178
498
retailer-min-distance-buffer
retailer-min-distance-buffer
"None" "500 Feet" "1000 Feet" "1500 Feet"
0

CHOOSER
8
503
146
548
retailer-removal
retailer-removal
"None" "Pharmacies" "Convenience"
0

BUTTON
11
552
132
585
NIL
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
595
450
652
495
NIL
day
17
1
11

SLIDER
7
91
247
124
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
890
57
1010
102
Area (square miles)
(world-height * world-width ) / 100
17
1
11

SWITCH
7
129
247
162
buy-cartons?
buy-cartons?
0
1
-1000

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
14
342
164
362
POLICY TESTING
16
0.0
0

BUTTON
78
167
166
200
NIL
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

MONITOR
500
450
593
495
NIL
average-costs
17
1
11

CHOOSER
256
451
438
496
visualise-mode-patches
visualise-mode-patches
"Smokers avg. purchase cost" "Smokers avg. purchase quantity" "Route length" "None"
3

BUTTON
440
451
495
542
visualise
visualise
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
260
571
410
597
Smokers
12
0.0
1

TEXTBOX
260
587
484
605
red --> smoker that made a purchase today
10
14.0
1

TEXTBOX
260
602
533
620
black --> smoker that did not make a purchase today
10
0.0
1

TEXTBOX
260
649
554
675
More saturated red patch colours indicate higher quantity/price
10
0.0
1

CHOOSER
256
497
438
542
visualise-mode-turtles
visualise-mode-turtles
"All agents" "Smokers only" "None"
1

TEXTBOX
260
631
410
649
Patches
12
0.0
1

CHOOSER
6
241
206
286
Smokers-parameters
Smokers-parameters
"Random (V)" "Random (V routes)" "Random rate (VC rates)" "Random inventory (VC inventory)" "Random wage (VC wage)" "Random transport (VC transport)" "Random routes (VC routes)" "All random (ignore random-spatial?)"
0

SWITCH
7
202
166
235
random-spatial?
random-spatial?
1
1
-1000

BUTTON
7
293
157
326
debug
setup\nask smoker 2078 [\ntype self type \" | \"\ntype \"wage = \" type wage type \", \"\ntype \"discount = \" type discount type \", \"\ntype \"inventory = \" type inventory type \", \"\ntype \"smoking-rate = \" type smoking-rate type \", \"\ntype \"transport-type = \" type transport-type type \"\\n\"\nask commute_nodes [set pcolor red]\n]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
806
423
947
456
override-wages?
override-wages?
0
1
-1000

SWITCH
808
536
954
569
override-rates?
override-rates?
0
1
-1000

SLIDER
703
464
875
497
wages-mean-W
wages-mean-W
5000
250000
50000.0
1000
1
NIL
HORIZONTAL

SLIDER
703
498
875
531
wages-std-W
wages-std-W
0
100000
5000.0
250
1
NIL
HORIZONTAL

SLIDER
703
573
875
606
rates-mean-W
rates-mean-W
0
60
20.0
1
1
NIL
HORIZONTAL

SLIDER
703
605
875
638
rates-std-W
rates-std-W
0
60
2.0
1
1
NIL
HORIZONTAL

SLIDER
879
497
1051
530
wages-std-E
wages-std-E
0
100000
5000.0
250
1
NIL
HORIZONTAL

SLIDER
879
464
1051
497
wages-mean-E
wages-mean-E
5000
250000
50000.0
1000
1
NIL
HORIZONTAL

SLIDER
879
575
1051
608
rates-mean-E
rates-mean-E
0
60
20.0
1
1
NIL
HORIZONTAL

SLIDER
879
607
1051
640
rates-std-E
rates-std-E
0
60
20.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## PATHFINDING 

Model uses distance off commute to retailer:

 - Nearest commute node to retailer is selected as starting point 

 - nw:distance-to retailer to calculate distance off route

## VARIABLES

-Fuel Price currently set to 5 American Automobile Association. (2102). Fuel Prices. Retrieved from http://fuelgaugereport.aaa.com/?redirectto=http://fuelgaugereport.opisnet.com/index.asp 


-Efficiency currently set to 18 US Department of Energy. (2012). Fuel Economy Guide. Retrieved from http://www.fueleconomy.gov/feg/pdfs/guides/feg2012.pdf

All other variables from Tobacco Town Supplement

## Interface

- `override-wages?` --> overrides the wages with a normal distribution
- `wages-mean-W` --> mean of the normal distribution for wages in the west side
- `wages-std-W` --> standard devisation of the normal distribution for wages in the west side
- `override-rates?` --> overrides the rates with a normal distribution
- `rates-mean-W` --> mean of the normal distribution for rates in the west side
- `rates-std-W` --> standard devisation of the normal distribution for rates
- `visualise-mode-patches` --> control the visualisation of patches
	- "Smokers avg. purchase cost": colour patches based on the median of the `smoker-average-overall-costs` for all the smokers in the patch
	- "Smokers avg. purchase quantity": colour patches based on the median of the `smoker-average-overall-quantity` for all the smokers in the patch
	- "None": colour all patches black
- `visualise-mode-agents` --> control the visualisation of agents
	- "All agents": show all the agents
	- "Smokers only": show the smokers only and set their size to 1
	- "None": show no agents

## Updates

Version 1.0.8 (YG)

1. Added the functionality to override smoking rates and wages at initialisation with an input normal distribution. The following parameters were added to the interface:
	- `override-wages?` --> overrides the wages with a normal distribution
	- `wages-mean-W` --> mean of the normal distribution for wages in the west side
	- `wages-std-W` --> standard devisation of the normal distribution for wages in the west side
	- `override-rates?` --> overrides the rates with a normal distribution
	- `rates-mean-W` --> mean of the normal distribution for rates in the west side
	- `rates-std-W` --> standard devisation of the normal distribution for rates in the west side
2. Modified the visualisation of histograms for a clearer representation when overriding smoking rates and wages

Version 1.0.7 (YG)

1. Addressed an issue where `generate-outlets` allocated outlets in all the space regardless of whether we input `neighbourhood` as "left" or "right"
2. Added a visualisation option for median route length

Version 1.0.6 (YG)

2. Added the functionality to create an initial space with urban poor in the west ("left") and urban rich in the east ("right"). An input labelled `neighbourhood` has been added to the following functions to control whether it is applied to the "left" or "right" side of the space.
	- all the `generate-smokers` functions
	- `generate-outlet-type`
	- `generate-workplaces`
	- `generate-schools`

Version 1.0.5 (YG)

1. Adressed an issue where `generate-smokers-VC-rate` generated fixed inventory values. This should not be the case as this function should only generate fixed smoking rates.
2. Added functions:
	- `generate-smokers-VC-wage` --> generate smokers with everything random except wages
	- `generate-smokers-VC-inventory` --> generate smokers with everything random except their inventory
	- `generate-smokers-VC-transport` --> generate smokers with everything random except transport types
	- `generate-smokers-VC-routes` --> generate smokers with everything random except transport routs
	- `generate-smokers-V-routes` --> generate smokers with everything random including routes

Note: `generate-smokers-V` generates smokers with everything random including transport routes

Version 1.0.4 (YG)

1. Renamed `random-seed?` to `random-spatial?` for clarity
2. Reversed the changes in the `generate-smokers` function to version 1.0.1
3. Added two functions:
	- `generate-smokers-V` --> generate smokers with random smoking rates and wages
	- `generate-smokers-VC-rate` --> generate smokers with random wages
4. Added a `smokers-parameters` input chooser with the following options:
	- "Random wages and smoking rates (V)" --> use `generate-smokers-V`
	- "Random wages (VC rates)" --> use `generate-smokers-VC-rates`
	- "All random (ignore random-spatial?)" --> use `generate-smokers`

Version 1.0.3 (YG)

1. Added the ability to replicate the same initial state at initialisation
	- Added a `random-seed?` switch representing whether the seed used during the setup of the spatial context is random or not
	- Modified the `setup` function to use a `random-seed` of 10 if `random-seed?` is switched off
	- Modified the `generate-smokers` function to control which parameters follow the `random-seed` at setup
		- The parameters following the setup seed are the: (1) wages, (2) smokers' homes, (3) smokers' work locations and (4) smokers' commute patches between work and home.
		- The parameter following a random seed is the smoking rate
2. Monitors
	- Added the global following global parameters to monitor their respective patch paramters as a list for all patches. The lists are sorted based on patches x and y coordinates.
		- `median-cost` --> `smokers-median-cost`
		- `median-quantity` --> `smokers-median-quantity`
		- `median-wage` --> `smokers-median-wage`
		- `median-rate` --> `smokers-median-rate`
	- Added an `update-globals` function to update the `median-cost` and `median-quantity` at any time step. This is only called in the behaviour space experiments.
3. Behaviour space
	- Added an experiment to observe the spatial propagational uncertainty from wages at initialisation to median purchase cost and quantity

Version 1.0.2 (YG)

1. Added `visualise-mode-patches` to control the visualisation of patches
	- "Smokers avg. purchase cost": colour patches based on the median of the `smoker-average-overall-costs` for all the smokers in the patch
	- "Smokers avg. purchase quantity": colour patches based on the median of the `smoker-average-overall-quantity` for all the smokers in the patch
	- "None": colour all patches black
2. Added `Visualise-mode-agents` to control the visualisation of agents
	- "All agents": show all the agents
	- "Smokers only": show the smokers only and set their size to 1
	- "None": show no agents
3. Added a `visualise` function to apply the visualisation. This function is only triggered when the `visualise` button is pressed.

Version 1.0.1 (YG)

1. The price calculation process was modified to be significantly more efficient
	- The price calculation now uses a steepest-descent hill-climbing algorithm
	- The algorithm starts with a `quantity` of 1 and checks whether the next increment of `quantity` is associated with a decrease in price (a descent).
	- If there is no decrease in price, the `current-price` and `quantity` are identified as one of the local-minima values in the optimisation algorithm.
	- If the smoker is willing to buy in packs, the optimisation algorithm checks the price of the closes higher `quantity` that is a factor of 10 (10 cigaretts represent a pack) - this is labelled as `quantity-tens` in the algorithm.
	- If the `quantity-tens` yields a lower `price` then this is identified as the new local minimum.
	- The algorithm resumes with a `quantity = quantity-tens` and checks whether the next increment leads to a decrease in price
	- The algorithm stops once the local minimum price found is lower that at its next `quantity-tens`.

Note: The global minimum value is always the first local minimum value found UNLESS the smoker is willing to buy packs. This creates cases where the global minimum is the price at the next increment of quantity that is divisible by 10. For instance, if the current found local minimum is 14 and the smoker buys packs, then it is possible that the global minimum is at a quantity of 20 (2 packs).
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
NetLogo 6.4.0
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
      <value value="&quot;Suburban Rich&quot;"/>
      <value value="&quot;Suburban Poor&quot;"/>
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;None&quot;"/>
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
  <experiment name="Retailer Distance Buffer" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Suburban Rich&quot;"/>
      <value value="&quot;Suburban Poor&quot;"/>
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;None&quot;"/>
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
  <experiment name="School Distance Buffer" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Suburban Rich&quot;"/>
      <value value="&quot;Suburban Poor&quot;"/>
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;None&quot;"/>
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
  <experiment name="Retailer Density Cap" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Suburban Rich&quot;"/>
      <value value="&quot;Suburban Poor&quot;"/>
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;None&quot;"/>
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
  <experiment name="Retailer Removal" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Suburban Rich&quot;"/>
      <value value="&quot;Suburban Poor&quot;"/>
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;Convenience&quot;"/>
      <value value="&quot;Pharmacies&quot;"/>
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
  <experiment name="High Strenght Combination" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Suburban Rich&quot;"/>
      <value value="&quot;Suburban Poor&quot;"/>
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;Convenience&quot;"/>
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
  <experiment name="Moderate Strenght Combination" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Suburban Rich&quot;"/>
      <value value="&quot;Suburban Poor&quot;"/>
      <value value="&quot;Urban Rich&quot;"/>
      <value value="&quot;Urban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;Pharmacies&quot;"/>
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
  <experiment name="Baseline (1)" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>run-fast</go>
    <metric>average-costs</metric>
    <metric>end-density</metric>
    <metric>average-purchase-quantity</metric>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Suburban Poor&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;None&quot;"/>
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
  <experiment name="uncertainy" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup
update-globals</setup>
    <go>run-fast
update-globals</go>
    <exitCondition>ticks = number-of-days</exitCondition>
    <metric>median-quantity</metric>
    <metric>median-cost</metric>
    <metric>median-wage</metric>
    <metric>median-rate</metric>
    <runMetricsCondition>ticks = 1 or ticks = 30</runMetricsCondition>
    <enumeratedValueSet variable="visualise-mode-patches">
      <value value="&quot;Smokers avg. purchase cost&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualise-mode-turtles">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="buy-cartons?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Urban Poor&quot;"/>
      <value value="&quot;Urban Poor | Urban Rich&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-min-distance-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-spatial?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-density-cap">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Smokers-parameters">
      <value value="&quot;Random (V)&quot;"/>
      <value value="&quot;Random (V routes)&quot;"/>
      <value value="&quot;Random rate (VC rates)&quot;"/>
      <value value="&quot;Random inventory (VC inventory)&quot;"/>
      <value value="&quot;Random wage (VC wage)&quot;"/>
      <value value="&quot;Random transport (VC transport)&quot;"/>
      <value value="&quot;Random routes (VC routes)&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="uncertainy_workOutletsEast_routes" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup
update-globals</setup>
    <go>run-fast
update-globals</go>
    <exitCondition>ticks = number-of-days</exitCondition>
    <metric>median-quantity</metric>
    <metric>median-cost</metric>
    <metric>median-wage</metric>
    <metric>median-rate</metric>
    <runMetricsCondition>ticks = 1 or ticks = 30</runMetricsCondition>
    <enumeratedValueSet variable="visualise-mode-patches">
      <value value="&quot;Smokers avg. purchase cost&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualise-mode-turtles">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="buy-cartons?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Urban Poor (no work or outlets) | Urban Rich&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-min-distance-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-spatial?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-density-cap">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Smokers-parameters">
      <value value="&quot;Random (V routes)&quot;"/>
      <value value="&quot;Random routes (VC routes)&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="uncertainty_controlRates" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup
update-globals</setup>
    <go>run-fast
update-globals</go>
    <exitCondition>ticks = number-of-days</exitCondition>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="buy-cartons?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="override-rates?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="override-wages?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-spatial?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rates-mean-E">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rates-mean-W">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rates-std-E">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rates-std-W">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-density-cap">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-min-distance-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Smokers-parameters">
      <value value="&quot;Random (V)&quot;"/>
      <value value="&quot;Random rate (VC rates)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Urban Rich&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualise-mode-patches">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualise-mode-turtles">
      <value value="&quot;Smokers only&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-mean-E">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-mean-W">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-std-E">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-std-W">
      <value value="5000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="uncertainty_controlWages" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup
update-globals</setup>
    <go>run-fast
update-globals</go>
    <exitCondition>ticks = number-of-days</exitCondition>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="buy-cartons?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-days">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="override-rates?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="override-wages?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-spatial?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rates-mean-E">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rates-mean-W">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rates-std-E">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rates-std-W">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-density-cap">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-min-distance-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailer-removal">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="school-buffer">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Smokers-parameters">
      <value value="&quot;Random (V)&quot;"/>
      <value value="&quot;Random wage (VC wage)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-type">
      <value value="&quot;Urban Rich&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualise-mode-patches">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualise-mode-turtles">
      <value value="&quot;Smokers only&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-mean-E">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-mean-W">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-std-E">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wages-std-W">
      <value value="30000"/>
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
