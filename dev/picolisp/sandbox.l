(= 2 2)
# => T

(= 2 3)
# => NIL

(+ 2 3)
# => 5

(cons 5 6)
# => (5 . 6)

'(7 . (8 9))
# => (7 8 9)

(de hello (name)
  (println 'greetings name)
  NIL)
# => hello

(hello 'conjurer)
# => greetings conjurer NIL
#    ^-----stdio------^ ^--return value

(apply * (range 1 6))
# => 720

(apply * (range 1 40))
# => 815915283247897734345611269596115894272000000000
