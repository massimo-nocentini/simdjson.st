Class {
	#name : 'SimdJSONNeoTestGenerator',
	#superclass : 'Object',
	#category : 'SimdJSON-NeoTests-Generator',
	#package : 'SimdJSON-NeoTests',
	#tag : 'Generator'
}

{ #category : 'accessing' }
SimdJSONNeoTestGenerator class >> classNames [
	"NeoJSON's test classes that read or write JSON"

	^ #( #NeoJSONReaderTests #NeoJSONWriterTests #NeoJSONMappingTests #NeoJSONExamplesTests #NeoJSONWriteReadTests
		#NeoJSONWriteReadMockStreamTests #NeoJSONWriteReadAsciiOnlyTests
		#NeoJSONWriteReadPrettyPrintedTests #NeoJSONObjectTests )
]

{ #category : 'generating' }
SimdJSONNeoTestGenerator class >> generate [
	"Make SJ<name> for each of the classNames, and answer them"

	(self classNames allSatisfy: [ :each | Smalltalk globals includesKey: each ]) ifFalse: [
		Transcript show: 'SimdJSON-NeoTests: Neo-JSON-Tests is not loaded, nothing generated'; cr.
		^ #() ].
	^ self classNames collect: [ :each | self generateFor: (Smalltalk globals at: each) ]
]

{ #category : 'generating' }
SimdJSONNeoTestGenerator class >> generateFor: aClass [
	"A subclass of aClass that inherits its tests and reads with SimdJSONReader; its tests
	 that only NeoJSON's leniency passes are skipped"

	| class |
	class := (aClass << ('SJ' , aClass name) asSymbol
		tag: 'Generated';
		package: self generatedPackageName) install.
	class class compile: 'shouldInheritSelectors' , String cr , String tab , '^ true' classified: 'testing'.
	(self selectorsToRewriteIn: aClass) do: [ :each |
		class compile: (self rewrite: (aClass lookupSelector: each) sourceCode) classified: 'simdjson' ].
	(self lenientTests at: aClass name ifAbsent: [ #() ]) do: [ :each |
		class
			compile: each , String cr , String tab , '^ self skip: ''NeoJSON reads this input by its leniency'''
			classified: 'simdjson' ].
	^ class
]

{ #category : 'accessing' }
SimdJSONNeoTestGenerator class >> generatedClasses [

	^ self classNames
		collect: [ :each | Smalltalk globals at: ('SJ' , each) asSymbol ifAbsent: [ nil ] ]
		thenSelect: [ :each | each notNil ]
]

{ #category : 'accessing' }
SimdJSONNeoTestGenerator class >> generatedPackageName [
	"The package of the SJ<name> classes: not SimdJSON-NeoTests, whose repository does not
	 track them"

	^ 'SimdJSON-NeoTests-Generated'
]

{ #category : 'generating' }
SimdJSONNeoTestGenerator class >> isIdentifierAt: index size: size in: source [

	| isPart |
	isPart := [ :position |
		(position between: 1 and: source size)
			and: [ (source at: position) isAlphaNumeric or: [ (source at: position) = $_ ] ] ].
	^ (isPart value: index - 1) not and: [ (isPart value: index + size) not ]
]

{ #category : 'accessing' }
SimdJSONNeoTestGenerator class >> lenientTests [
	"The tests of NeoJSON, by class, that read an input which only NeoJSON's leniency
	 accepts, and which SimdJSONReader refuses: testIntegers reads 00123, -0123 and 00,
	 with leading zeros"

	^ Dictionary new
		at: #NeoJSONReaderTests put: #( #testIntegers );
		yourself
]

{ #category : 'reading' }
SimdJSONNeoTestGenerator class >> objectFromString: aString [
	"What NeoJSONObject fromString: answers, read by SimdJSONReader: NeoJSONObjects with
	 Symbol keys, and NeoJSONArrays"

	^ (SimdJSONReader on: aString readStream)
		mapClass: (Smalltalk globals at: #NeoJSONObject);
		listClass: (Smalltalk globals at: #NeoJSONArray);
		propertyNamesAsSymbols: true;
		next
]

{ #category : 'generating' }
SimdJSONNeoTestGenerator class >> replaceIdentifier: old with: new in: source [
	"Each occurrence of old that is not a part of a longer identifier"

	^ String streamContents: [ :stream |
		| start index |
		start := 1.
		[ (index := source indexOfSubCollection: old startingAt: start) > 0 ] whileTrue: [
			stream
				nextPutAll: (source copyFrom: start to: index - 1);
				nextPutAll: ((self isIdentifierAt: index size: old size in: source) ifTrue: [ new ] ifFalse: [ old ]).
			start := index + old size ].
		stream nextPutAll: (source copyFrom: start to: source size) ]
]

{ #category : 'reporting' }
SimdJSONNeoTestGenerator class >> report [
	"Run the generated classes; print, for each, what passed of what ran and what was
	 skipped, then answer the total"

	| out run passed |
	out := Stdio stdout.
	run := passed := 0.
	self generatedClasses do: [ :class |
		| result |
		result := class buildSuite run.
		out
			nextPutAll: class name; nextPutAll: ': ';
			print: result passedCount; nextPut: $/; print: result runCount;
			nextPutAll: ' passed, ';
			print: result skippedCount; nextPutAll: ' skipped (lenient)'; lf.
		result failures , result errors do: [ :each |
			out nextPutAll: '    failed: '; nextPutAll: each selector; lf ].
		run := run + result runCount.
		passed := passed + result passedCount ].
	out flush.
	^ 'SJ*: ' , passed printString , '/' , run printString , ' passed'
]

{ #category : 'generating' }
SimdJSONNeoTestGenerator class >> rewrite: source [
	"NeoJSONObject fromString:, and the identifiers NeoJSONReader, NeoJSONWriter,
	 NeoJSONParseError and NeoJSONMappingNotFound, for SimdJSON's"

	| result |
	result := source copyReplaceAll: 'NeoJSONObject fromString:' with: 'SimdJSONNeoTestGenerator objectFromString:'.
	#( #( 'NeoJSONReader' 'SimdJSONReader' ) #( 'NeoJSONWriter' 'SimdJSONWriter' ) #( 'NeoJSONParseError' 'SimdJSONParseError' )
	   #( 'NeoJSONMappingNotFound' 'SimdJSONMappingNotFound' ) ) do: [ :pair |
		result := self replaceIdentifier: pair first with: pair last in: result ].
	^ result
]

{ #category : 'generating' }
SimdJSONNeoTestGenerator class >> selectorsToRewriteIn: aClass [
	"The selectors of aClass and of its superclasses below TestCase whose method reads JSON
	 with NeoJSON: inherited methods too, so that each class reads with SimdJSONReader"

	| selectors |
	selectors := Set new.
	(aClass withAllSuperclasses copyUpTo: TestCase) do: [ :each | selectors addAll: each selectors ].
	^ (selectors select: [ :each |
		| source |
		source := (aClass lookupSelector: each) sourceCode.
		(self rewrite: source) ~= source ]) asArray sort
]
