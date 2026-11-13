Extension { #name : 'ProtoObject' }

{ #category : '*SimdJSON' }
ProtoObject >> isSimdJSONPlain [
	"Whether primitiveWrite writes me itself, and the writer gives me to it (nil, the
	Booleans and the SmallIntegers the writer writes itself); a proxy answers for itself, not
	for the object it stands for, as primitiveWrite looks at its class"

	^ false
]

{ #category : '*SimdJSON' }
ProtoObject >> simdJSONContents [
	"The text a stream reads, when the plugin can read it in place, or nil; a proxy of a
	ReadStream answers for itself, and is read to its end as any other stream"

	^ nil
]

{ #category : '*SimdJSON' }
ProtoObject >> simdJSONSink [
	"The stream the JSON goes to when written on me: as the class of what I stand for chooses
	(its simdJSONSinkOf:), with me as the stream; I stand for myself, unless I am a proxy that
	forwards simdJSONSinkOf:"

	^ self simdJSONSinkOf: self
]

{ #category : '*SimdJSON' }
ProtoObject >> simdJSONSinkFor: aStream [
	"The stream the JSON goes to when written on aStream, which encodes with me: aStream
	itself.  Here, not in ZnCharacterEncoder, so that an encoder of another hierarchy that a
	ZnCharacterWriteStream is given still encodes the JSON; a proxy answers for itself, and
	aStream encodes the JSON with it"

	^ aStream
]

{ #category : '*SimdJSON' }
ProtoObject >> simdJSONSourceKind [
	"#string, #bytes (UTF-8) or nil: how the reader reads me in place, the collection of a
	ReadStream; classifyStream copies any other one into a String (primitiveRead takes
	more: SimdJSONLibrary>>passable:); a proxy answers for itself, as primitiveRead looks at
	its class"

	^ nil
]

{ #category : '*SimdJSON' }
ProtoObject >> simdJSONWriteOn: aWriter [
	"Write me on aWriter as NeoJSON's neoJsonOn: does: as the class of what I stand for
	chooses (its simdJSONWrite:on:), with the mapping of my own class; I stand for myself,
	unless I am a proxy that forwards simdJSONWrite:on:"

	^ self simdJSONWrite: self on: aWriter
]
