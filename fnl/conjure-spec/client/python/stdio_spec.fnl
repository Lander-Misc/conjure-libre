(local {: describe : it} (require :plenary.busted))
(local assert (require :luassert.assert))
(local python (require :conjure.client.python.stdio))

(describe "conjure.client.python.stdio"
  (fn []
    (describe "prep-code"
      (fn []
        (it "sets __file__ before evaluating expressions"
            (fn []
              (tset python :str-is-python-expr? (fn [_] true))

              (assert.same
                "__file__ = base64.b64decode('L3RtcC9leGFtcGxlLnB5').decode()\n__file__\n"
                (python.prep-code
                  {:code "__file__"
                   :file-path "/tmp/example.py"}))))

        (it "sets __file__ and uses it as the filename for exec evaluations"
            (fn []
              (tset python :str-is-python-expr? (fn [_] false))

              (assert.same
                "__file__ = base64.b64decode('L3RtcC9leGFtcGxlLnB5').decode()\nexec(compile(base64.b64decode('cHJpbnQoX19maWxlX18p'), __file__, 'exec'))\n"
                (python.prep-code
                  {:code "print(__file__)"
                   :file-path "/tmp/example.py"}))))

        (it "uses a fallback filename when no file path is available"
            (fn []
              (tset python :str-is-python-expr? (fn [_] true))

              (assert.same
                "__file__ = base64.b64decode('PGNvbmp1cmU+').decode()\n__file__\n"
                (python.prep-code
                  {:code "__file__"}))))))))
