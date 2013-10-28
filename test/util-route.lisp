(in-package :open-vrp.test)

;; Route utilities
;; --------------------

(define-test route-utils
  "Test the no-visits-p/get-busy-vehicles/one-destination-p utils"
  (:tag :route)
  (let* ((t0 (make-vehicle :id :0))
         (t1 (make-vehicle :id :1 :route (list (make-order :node-id :O1))))
         (t2 (make-vehicle :id :2 :route (list (make-order :node-id :O5)
                                               (make-order :node-id :O8)
                                               (make-order :node-id :O6))))
         (t3 (make-vehicle :id :3 :route (list (make-pitstop :node-id :P1))))
         (prob (make-instance 'problem :fleet (list t0 t1 t2 t3))))
    (assert-true (no-visits-p (vehicle-route t0)))
    (assert-true (no-visits-p (vehicle-route t3)))
    (assert-false (no-visits-p (vehicle-route t1)))
    (assert-false (no-visits-p (vehicle-route t2)))
    (assert-error 'simple-type-error (no-visits-p t0))
    (assert-true (one-destination-p (vehicle-route t1)))
    (assert-false (one-destination-p (vehicle-route t2)))
    (assert-error 'simple-type-error (one-destination-p t0))
    (assert-equal 2 (length (get-busy-vehicles prob)))
    (assert-error 'simple-type-error (get-busy-vehicles t0))
    (assert-error 'index-out-of-bounds (insert-node t0 (make-order :node-id :A1) 1))

    ;; Destructive tests
    (insert-node t0 (make-order :node-id :A0) 0)
    (insert-node t1 (make-order :node-id :A1) 1)
    (assert-equal '(:O1 :A1) (route-indices t1))
    (insert-node t2 (make-order :node-id :A2) 2)
    (assert-equal '(:O5 :O8 :A2 :O6) (route-indices t2))
    (append-node t3 (make-order :node-id :A3))
    (assert-equal '(:P1 :A3) (route-indices t3))
    (append-node t3 (make-order :node-id :A3B))
    (assert-equal '(:P1 :A3 :A3B) (route-indices t3))
    (remove-node-id t0 :A0)
    (assert-true (no-visits-p (vehicle-route t0)))
    (remove-node-id t1 :A1)
    (assert-true (one-destination-p (vehicle-route t1)))
    (remove-node-id t2 :A2)
    (assert-equal '(:O5 :O8 :O6) (route-indices t2))
    (assert-equal nil (remove-node-id t2 :A2))
    (remove-node-id prob :O1)
    (remove-node-id prob :A3)
    (remove-node-id prob :A3B)
    (remove-node-id prob :O8)
    (assert-true (no-visits-p (vehicle-route t1)))
    (assert-true (no-visits-p (vehicle-route t3)))
    (assert-equal '(:O5 :O6) (route-indices t2))))

(define-test unserved-list
  "Test the unserved-list"
  (:tag :route)
  (let ((prob (make-instance 'problem :allow-unserved t)))
    (assert-equal '() (problem-unserved prob))
    (add-to-unserved prob :A)
    (assert-equal '(:A) (problem-unserved prob))
    (add-to-unserved prob :B)
    (assert-equal '(:B :A) (problem-unserved prob))
    (remove-from-unserved prob :A)
    (assert-equal '(:B) (problem-unserved prob))))
