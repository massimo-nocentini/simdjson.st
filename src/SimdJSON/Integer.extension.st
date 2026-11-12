Extension { #name : 'Integer' }

{ #category : '*SimdJSON' }
Integer >> simdJSONKeyIn: aKeyTable [
	"A key of the tree, the index of a Symbol in aKeyTable: that Symbol"

	^ aKeyTable at: self
]

{ #category : '*SimdJSON' }
Integer >> simdJSONWrite: anObject on: aWriter [
	"My digits"

	^ aWriter writeInteger: anObject
]
