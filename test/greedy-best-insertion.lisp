(in-package :open-vrp.test)

;; Greedy best insertion algo
;; --------------------

(define-test greedy-best-insertion-test
  (:tag :greedy)
  "Test greedy-best-insertion algorithm to generate initial feasible solutions"
  (let* ((o1 (make-order :duration 1 :start 0 :end 11 :node-id :o1 :demand 1))
         (o2 (make-order :duration 2 :start 0 :end 20 :node-id :o2 :demand 1))
         (o3 (make-order :duration 3 :start 10 :end 13 :node-id :o3 :demand 1))
         (o4 (make-order :duration 4 :start 10 :end 14 :node-id :o4 :demand 1))
         (o5 (make-order :duration 5 :start 10 :end 20 :node-id :o5 :demand 1))
         (t1 (make-vehicle :id :t1 :start-location :A :end-location :B :shift-end 25 :capacity 2))
         (t2 (make-vehicle :id :t2 :start-location :A :end-location :B :shift-start 10 :shift-end 25 :capacity 20 :speed 0.1))
         (t3 (make-vehicle :id :t3 :start-location :A :end-location :B :shift-start 0 :shift-end 100 :capacity 20 :speed 10))
         (dist {:o1 {      :o2 1 :o3 2 :o4 3 :o5 5 :A 1 :B 4}
                :o2 {:o1 1       :o3 1 :o4 2 :o5 4 :A 2 :B 3}
                :o3 {:o1 2 :o2 1       :o4 1 :o5 3 :A 3 :B 2}
                :o4 {:o1 3 :o2 2 :o3 1       :o5 1 :A 4 :B 1}
                :o5 {:o1 4 :o2 3 :o3 2 :o4 1       :A 6 :B 2}
                :A  {:o1 1 :o2 2 :o3 3 :o4 4 :o5 6      :B 5}
                :B  {:o1 4 :o2 3 :o3 2 :o4 1 :o5 2 :A 5     }})
         (prob (make-instance 'problem :fleet (list t1 t2)
                              :dist-matrix dist
                              :visits {:o1 o1 :o2 o2 :o3 o3 :o4 o4 :o5 o5}))
         (cvrp (make-instance 'cvrp :fleet (list t1 t2)
                              :dist-matrix dist
                              :visits {:o1 o1 :o2 o2 :o3 o3 :o4 o4 :o5 o5}))
         (vrptw (make-instance 'vrptw :fleet (list t1 t2) :allow-unserved nil
                               :dist-matrix dist
                               :visits {:o1 o1 :o2 o2 :o3 o3 :o4 o4 :o5 o5}))
         (cvrptw (make-instance 'cvrptw :fleet (list t3)
                                :dist-matrix dist
                                :visits {:o1 o1 :o2 o2 :o3 o3 :o4 o4 :o5 o5}))
         (prob-sol (solve-prob prob (make-instance 'greedy-best-insertion)))
         (cvrp-sol (solve-prob cvrp (make-instance 'greedy-best-insertion))))
    (assert-equal 7 (algo-best-fitness prob-sol))
    (assert-equal '((:A :O1 :O2 :O3 :O4 :O5 :B) (:A :B))
                  (route-indices (algo-best-sol prob-sol)))
    (assert-true (<= (algo-best-fitness cvrp-sol) 13))
    (assert-true (= 2 (length (vehicle-route (vehicle (algo-best-sol cvrp-sol) :T1)))))
    (assert-true (= 3 (length (vehicle-route (vehicle (algo-best-sol cvrp-sol) :T2)))))
    (assert-error 'no-initial-feasible-solution (solve-prob vrptw (make-instance 'greedy-best-insertion)))
    (assert-equal '((:A :O1 :O2 :O3 :O4 :O5 :B))
                  (route-indices (algo-best-sol (solve-prob cvrptw (make-instance 'greedy-best-insertion)))))))
