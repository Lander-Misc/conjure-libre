(var last-opts nil)

(var mock-send (fn [_]))

(local set-mock-send (fn [send]
  (set mock-send send)))

(local start
  (fn [opts]
    (set last-opts opts)
    {:send mock-send
     :destroy (fn [])}))

{ :get-last-opts (fn [] last-opts)
  : start
  : set-mock-send }

