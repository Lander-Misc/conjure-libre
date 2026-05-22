(local {: describe : it} (require :plenary.busted))
(local assert (require :luassert.assert))
(local event (require :conjure.event))

(fn flush []
  (vim.wait 50 (fn [] false)))

(fn capture-data [pattern]
  (let [state {:fired 0 :data nil}
        group (vim.api.nvim_create_augroup
                (.. "conjure-spec-event-" pattern)
                {:clear true})]
    (vim.api.nvim_create_autocmd
      :User
      {: pattern
       : group
       :callback (fn [ev]
                   (set state.fired (+ state.fired 1))
                   (set state.data ev.data))})
    state))

(describe "conjure.event"
  (fn []
    (describe "emit-data"
      (fn []
        (it "fires a User Conjure<Name> autocmd carrying the data payload"
          (fn []
            (let [state (capture-data :ConjureSpecfoo)]
              (event.emit-data :specfoo "hello world")
              (flush)
              (assert.are.equals 1 state.fired)
              (assert.are.equals "hello world" state.data))))

        (it "upper-cases the first character of the event name"
          (fn []
            (let [state (capture-data :ConjureBar)]
              (event.emit-data :bar "x")
              (flush)
              (assert.are.equals "x" state.data))))

        (it "passes table data through unchanged"
          (fn []
            (let [state (capture-data :ConjureBaz)
                  payload {:hello :world :n 1}]
              (event.emit-data :baz payload)
              (flush)
              (assert.same payload state.data))))))))
