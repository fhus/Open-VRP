(defsystem :open-vrp-lib
  :description "open-vrp-library"
  :author "mck- <kuomarc2@gmail.com>"
  :licence "LLGPL"
  :depends-on (#:vecto #:alexandria #:cl-fad)
  :serial t
  :components ((:file "packages")
               (:module :lib
                        :components
                        ((:file "class-definitions")
                         (:file "hash-table")
                         (:file "simple-utils")
                         (:file "list")
                         (:file "network")
                         (:file "fleet")
                         (:file "fitness")
                         (:file "output")
                         (:file "route")
                         (:file "time")
                         (:file "conditions")
                         (:file "constraints")
                         (:file "solver")))))
