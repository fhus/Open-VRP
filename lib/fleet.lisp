;;; Fleet related functions
;;; ---------------------------
;;; - route-indices (<vehicle>/<problem>)      - returns list of node IDs
;;; - vehicle-with-node-id (<Problem> keyword) - returns <vehicle> that has the node-ID
;;; - route-dist (<vehicle> dist-matrix)       - returns the total distance given <vehicle>
;;; - total-dist (<problem>)                   - returns the total distance given <Problem>
;;; - veh-arrival-times (<vehicle> dist-matrix)- returns list of arrival times along route
;;; - arrival-times (<problem>)                - returns list of lists of arrival times
;;; - vehicle (<problem> keyword)              - returns <Vehicle> with id

(in-package :open-vrp.util)

(defgeneric route-indices (obj)
  (:method (vehicle) "Input is not a <vehicle>/<problem> object!")
  (:documentation "When input is a <vehicle>, returns its route as a list of node IDs. When input is <fleet>/<problem>, list all routes."))

(defmethod route-indices ((v vehicle))
  (if (or (eq :nil (vehicle-start-location v))
          (eq :nil (vehicle-end-location v)))
      (mapcar #'visit-node-id (vehicle-route v))
      (nconc (list (vehicle-start-location v))
             (mapcar #'visit-node-id (vehicle-route v))
             (list (vehicle-end-location v)))))

(defmethod route-indices ((p problem))
  (mapcar #'route-indices (problem-fleet p)))

(defun node-on-route-p (node-id vehicle)
  "Returns NIL if <vehicle> does not have the node on its route."
  (check-type node-id symbol)
  (check-type vehicle vehicle)
  (find node-id (vehicle-route vehicle) :key #'visit-node-id))

(defun vehicle-with-node-id (prob node-id)
  "Given a node-id, return the vehicle-id that has the node in its route. Returns NIL if node-id cannot be found. Assumes only 1 presence of a node in the problem. When allow-unserved is T, also search the unserved slot in problem, and return :UNSERVED if it is found there."
  (check-type prob problem)
  (check-type node-id symbol)
  (or (reduce
       (lambda (x y)
         (or x (when (node-on-route-p node-id y)
                 (vehicle-id y))))
       (problem-fleet prob)
       :initial-value nil)
      (when (and (problem-allow-unserved prob)
                 (member node-id (problem-unserved prob)))
        :UNSERVED)))

(defun route-dist (veh dist-matrix)
  "Returns total distance of the route(s) given a vehicle. Takes into account the start and end locations of the vehicle."
  (check-type veh vehicle)
  (check-type dist-matrix hash-table)
  (labels ((iter (togo sum)
             (if (null (cdr togo)) sum
                 (iter (cdr togo)
                       (+ sum
                          (get-distance (car togo)
                                        (cadr togo)
                                        dist-matrix))))))
    ;; Insert start and end-locations into route
    (iter (route-indices veh) 0)))


(defun total-dist (problem)
  "Returns total distance of all routes combined. Includes to and from start and end locations."
  (loop for v in (get-busy-vehicles problem) sum (route-dist v (problem-dist-matrix problem))))

(defun veh-arrival-times (veh dist-matrix)
  "Returns arrival times at each node along a vehicle's route"
  (let ((times (list (vehicle-shift-start veh))))
    (labels ((iter (route time loc)
               (if (null route) (nreverse
                                 (push
                                  (+ time (travel-time loc (vehicle-end-location veh) dist-matrix :speed (vehicle-speed veh)))
                                  times))
                   (let ((arr-time (+ time (travel-time loc (visit-node-id (car route)) dist-matrix :speed (vehicle-speed veh)))))
                     (push arr-time times)
                     (iter (cdr route)
                           (time-after-visit (car route) arr-time)
                           (visit-node-id (car route)))))))
      (iter (vehicle-route veh)
            (vehicle-shift-start veh)
            (vehicle-start-location veh)))))

(defun arrival-times (sol)
  "Given a solution, return a list of lists of arrival times."
  (mapcar #'(lambda (v) (veh-arrival-times v (problem-dist-matrix sol)))
          (problem-fleet sol)))

;; Accessor functions
;; ------------------
(defmethod vehicle ((p problem) id)
  (aif (find id (problem-fleet p) :key #'vehicle-id)
       it
       (error 'vehicle-not-found :id id)))

;; ------------------
