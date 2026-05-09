(local {: describe : it : before_each : after_each} (require :plenary.busted))
(local assert (require :luassert.assert))
(local res (require :conjure.resources))
(local ts (require :conjure.tree-sitter))
(local tsc (require :conjure.tree-sitter-completions))

(var saved-get-resource-contents nil)
(var saved-parse! nil)
(var saved-query-parse nil)
(var saved-language-inspect nil)
(var saved-get-node nil)

(describe
  "make-prefix-filter"
  (fn []
    (it "filters to aaa from aaa bbb abb with prefix aa"
        (fn []
          (let [filter (tsc.make-prefix-filter "aa")]
            (assert.same [:aaa] (filter [:aaa :bbb :abb])))))

    (it "filters to %thing from aaa %thing b%b with prefix %"
        (fn []
          (let [filter (tsc.make-prefix-filter "%")]
            (assert.same [:%thing] (filter [:aaa :%thing :b%b])))))

    (it "filters nothing from aaa word 2342 with prefix nil"
        (fn []
          (let [filter (tsc.make-prefix-filter nil)]
            (assert.same [:aaa :word :2342] (filter [:aaa :word :2342])))))))

(describe
  "get-completions-at-cursor"
  (fn []
    (before_each
      (fn []
        (set saved-get-resource-contents res.get-resource-contents)
        (set saved-parse! ts.parse!)
        (set saved-query-parse vim.treesitter.query.parse)
        (set saved-language-inspect vim.treesitter.language.inspect)
        (set saved-get-node vim.treesitter.get_node)))

    (after_each
      (fn []
        (tset res :get-resource-contents saved-get-resource-contents)
        (tset ts :parse! saved-parse!)
        (tset vim.treesitter.query :parse saved-query-parse)
        (tset vim.treesitter.language :inspect saved-language-inspect)
        (tset vim.treesitter :get_node saved-get-node)))

    (it "returns no completions when the tree-sitter language is unavailable"
        (fn []
          (tset res :get-resource-contents (fn [_] "(query)"))
          (tset vim.treesitter.language :inspect
                (fn [_] (error "language not found")))
          (tset vim.treesitter.query :parse
                (fn [_ _] (error "query parse should not be called")))

          (assert.same [] (tsc.get-completions-at-cursor
                            :missing-test-lang
                            :missing-test-resource))))

    (it "returns no completions when parsing the current buffer fails"
        (fn []
          (tset res :get-resource-contents (fn [_] "(query)"))
          (tset vim.treesitter.language :inspect (fn [_] {}))
          (tset vim.treesitter.query :parse (fn [_ _] {}))
          (tset ts :parse! (fn [] nil))
          (tset vim.treesitter :get_node
                (fn [] (error "get_node should not be called")))

          (assert.same [] (tsc.get-completions-at-cursor
                            :parse-fail-test-lang
                            :parse-fail-test-resource))))))
