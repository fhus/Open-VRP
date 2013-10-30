;; Best Insertion (used by Tabu Search)
;; -------------
;; The following functions are defined to generate-assess-choose the best insertion move
;; for a node into a vehicle's route. Assumes the route does not include the node already.
;; - get-best-insertion-move expects a <solution> object, a node-id and a vehicle-id.
;; -----------------------------------------------
(in-package :open-vrp.algo)

(defun generate-insertion-moves (sol vehicle-id node-id)
  "Given the <solution> object, vehicle-id and node-id (integers), create all possible insertion-moves, and return them in a list. Avoid generating moves that won't do anything (when doing intra-route insertion)."
  (let* ((route (vehicle-route (vehicle sol vehicle-id)))
         (pos (position node-id route :key #'visit-node-id)) ;check if we do intra-route insertion
         (moves '()))
    (do ((index 0 (1+ index)))
        ((> index (length route)))
      (unless (and pos (or (= index pos) (= index (1+ pos)))) ;useless moves avoided
        (push (make-insertion-move
               :index index
               :vehicle-id vehicle-id
               :node-id node-id)
              moves)))
    moves))

;; calculates the added distance of performing the insertion-move
;; it is the distance to the nodes before and after, minus their direct connection
(defmethod assess-move ((sol problem) (m insertion-move))
  (with-slots (node-id vehicle-id index) m
    (let* ((veh (vehicle sol vehicle-id))
           (route (vehicle-route veh))
           (dist-matrix (problem-dist-matrix sol))
           (node-before (if (= index 0)
                            (vehicle-start-location veh)
                            (visit-node-id (nth (1- index) route))))
           (node-after (if (= index (length route))
                           (vehicle-end-location veh)
                           (visit-node-id (nth index route)))))
      (setf (move-fitness m)
            (handler-case
                (-
                 (+ (distance node-before node-id dist-matrix)
                    (distance node-id node-after dist-matrix))
                 (distance node-before node-after dist-matrix))
              (distance-between-nodes-undefined () nil))))))

(defmethod perform-move ((sol problem) (m insertion-move))
  "Performs the <move> on <problem>."
  (with-slots (node-id vehicle-id index) m
    (insert-node (vehicle sol vehicle-id) (visit-node sol node-id) index)
    sol))

;; logging
(defmethod perform-move :after ((prob problem) (mv insertion-move))
  (with-log-or-print (stream prob *start-time*)
    (format stream "~&Performing ~A with Node ~A and Vehicle ~A and Index ~A~%" (type-of mv) (move-node-ID mv) (move-vehicle-ID mv) (move-index mv))))

;; ----------------------

;; Optimal insertion (used by Greedy Best Insertion)
;; ---------------------

;; Step 1: find best index, given vehicle-id
(defun get-best-insertion-move-in-vehicle (sol vehicle-id node-id)
  "Given the <solution> object, vehicle-id and node-id (integers), return the best <insertion-move> (i.e. with the lowest fitness) for inserting node-id in vehicle-id. When no move is feasible, throws error."
  (let ((sorted (sort-moves (assess-moves sol (generate-insertion-moves sol vehicle-id node-id)))))
    (unless sorted (error 'no-feasible-move :moves sorted))
    (car sorted)))

;; Step 2: find best vehicle, given node
(defun get-best-insertion-move (sol node-id)
  "Given a node-id and a solution (that does not have this node yet), return the best <insertion-move>."
  (check-type sol problem)
  (check-type node-id symbol)
  (labels ((iter (flt best-move)
             (if (null flt) (or best-move (error 'no-feasible-move))
                 (iter (cdr flt)
                       (handler-case
                           (let ((new (get-best-insertion-move-in-vehicle sol
                                                                          (vehicle-id (car flt))
                                                                          node-id)))
                             (if (or (null best-move) ;first move
                                     (< (move-fitness new) (move-fitness best-move))) ;better?
                                 new
                                 best-move))
                         (no-feasible-move () best-move))))))
    (iter (problem-fleet sol) nil)))

;; -------------------------
