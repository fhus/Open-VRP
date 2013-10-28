;;; Functions to operate on routes, which are a list of <node> objects
;;; contained in a <vehicle>'s :route slot.
(in-package :open-vrp.util)
;;; -------
;;; 0. Route utils
;;; 1. Insert node into the route
;;; 2. Remove node from the route
;;; 3. Add to unserved list
;;; --------------------

;; 0. Route utils
;; ---------------------
(defun no-visits-p (route)
  "Given a route, return T if the route does not contain any orders (pitstops do not count)."
  (check-type route sequence)
  (notany #'order-p route))

(defun get-busy-vehicles (problem)
  "Returns a list of <Vehicles> that are not empty, given a <Problem> object."
  (check-type problem problem)
  (remove-if #'no-visits-p (problem-fleet problem) :key #'vehicle-route))

(defun one-destination-p (route)
  "Return T if there is only one order on route."
  (check-type route sequence)
  (= 1 (count-if #'order-p route)))

(defmacro with-changing-route ((var vehicle) &body body)
  "Expands into binding the vehicles route to var and setting it to result of body."
  `(let ((,var (vehicle-route ,vehicle)))
     (setf (vehicle-route ,vehicle) ,@body)))
;; ------------------

;; 1. Insert Node
;; -------------------

(defun insert-node (veh node index)
  "Adds the <Node> object before the index of the route of <vehicle>. An index of 0 implies inserting in front, length of list implies at the end."
  (with-changing-route (r veh)
    (insert-before node index r)))

(defun append-node (veh node)
  "Appends <Node> to the end of the route of <vehicle>. Wrapper of insert-node."
  (with-changing-route (r veh)
    (insert-before node (length r) r)))

;; -------------------------

;; 2. Remove Node
;; -------------------------
(defgeneric remove-node-id (veh/prob node-id)
  (:method (vehicle node-id) "Expects <vehicle>/<problem> and int as inputs!")
  (:documentation "Removes the <node> with node-id from the route of <vehicle>. Returns NIL if failed to find node-id. When <problem> is given, remove the node from the first vehicle that holds it (should not occur more than once anyway). Also supports removing from UNSERVED list, if it is held there."))

(defmethod remove-node-id ((v vehicle) node-id)
  (if (node-on-route-p node-id v)
      (with-changing-route (r v)
        (remove node-id r :key #'visit-node-id :count 1)) ;count 1 for perform-move in TS.lisp.
      nil))

(defmethod remove-node-id ((prob problem) node-id)
  (aif (vehicle-with-node-id prob node-id)
       (if (eq :UNSERVED it)
           (remove-from-unserved prob node-id)
           (remove-node-id (vehicle prob it) node-id))
       nil))
;; ----------------------------

;; 3. Add to unserved list
;; ----------------------------
(defun add-to-unserved (prob node-id)
  "Add node-id to the unserved list in problem"
  (check-type prob problem)
  (check-type node-id symbol)
  (push node-id (problem-unserved prob)))

(defun remove-from-unserved (prob node-id)
  "Remove node-id from the unserved list in problem"
  (check-type prob problem)
  (check-type node-id symbol)
  (setf (problem-unserved prob) (remove node-id (problem-unserved prob))))

;; ---------------------------
