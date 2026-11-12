"
The baseline of SimdJSON (https://github.com/massimo-nocentini/simdjson.st), a JSON reader and writer for Pharo 15 on the SimdJSONPlugin of the VM.

Groups: Core (the package SimdJSON, which needs no other project), Tests (SimdJSON-Tests), FFI (SimdJSON-FFI: the reader without the plugin, through the FFI and the library libSimdJSONFFI), FFITests (SimdJSON-FFI-Tests), NeoTests (SimdJSON-NeoTests, which needs NeoJSON with its tests, and generates the SJ<name> classes in SimdJSON-NeoTests-Generated after it is loaded); default loads all of them.
"
Class {
	#name : 'BaselineOfSimdJSON',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfSimdJSON',
	#package : 'BaselineOfSimdJSON'
}

{ #category : 'baselines' }
BaselineOfSimdJSON >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec baseline: 'NeoJSON' with: [
			spec
				repository: 'github://svenvc/NeoJSON:master/repository';
				loads: #( 'core' 'tests' ) ].
		spec
			package: 'SimdJSON';
			package: 'SimdJSON-Tests' with: [ spec requires: #( 'SimdJSON' ) ];
			package: 'SimdJSON-FFI' with: [ spec requires: #( 'SimdJSON' ) ];
			package: 'SimdJSON-FFI-Tests' with: [ spec requires: #( 'SimdJSON-FFI' 'SimdJSON-Tests' ) ];
			package: 'SimdJSON-NeoTests' with: [
				spec
					requires: #( 'SimdJSON' 'NeoJSON' );
					postLoadDoIt: #generateNeoTests ].
		spec
			group: 'Core' with: #( 'SimdJSON' );
			group: 'Tests' with: #( 'SimdJSON-Tests' );
			group: 'FFI' with: #( 'SimdJSON-FFI' );
			group: 'FFITests' with: #( 'SimdJSON-FFI-Tests' );
			group: 'NeoTests' with: #( 'SimdJSON-NeoTests' );
			group: 'default' with: #( 'Core' 'Tests' 'FFI' 'FFITests' 'NeoTests' ) ]
]

{ #category : 'actions' }
BaselineOfSimdJSON >> generateNeoTests [
	"After SimdJSON-NeoTests is loaded: make the SJ<name> subclasses of NeoJSON's tests,
	 in the package SimdJSON-NeoTests-Generated, which the repository does not track"

	Transcript
		show: 'SimdJSON-NeoTests: generated ' , (Smalltalk globals at: #SimdJSONNeoTestGenerator) generate size printString , ' classes';
		cr
]
