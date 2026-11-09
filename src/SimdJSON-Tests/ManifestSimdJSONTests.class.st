"
SimdJSON-Tests - the SUnit tests of the package SimdJSON

They need no NeoJSON, and pass whether NeoJSON is in the image or not:
SimdJSONReader has none of its classes in its hierarchy, and is strict
RFC 8259 (NeoJSON's leniencies raise SimdJSONParseError).
The package SimdJSON-NeoTests compares the reader with NeoJSON itself.

	SimdJSONReaderTests   the reader API: values, numbers, strings, classes,
	                      sources, stream positions, NDJSON, errors
	SimdJSONNativeTests   the Dictionaries built by the plugin against the
	                      tree path, their self-test and the kill switch
	SimdJSONMemoryTests   the budget of primitiveRead, the exact need, and
	                      the grow of the reader
	SimdJSONMappingTests  nextAs: and the mapper protocol of NeoJSON
	SimdJSONWriterTests   SimdJSONWriter: the texts of NeoJSONWriter (numbers,
	                      strings, escapes, pretty printing), streams, bytes,
	                      forwarders, the objects the plugin leaves to the
	                      image (holes), mappings, writers of their own, the
	                      streaming protocol and errors
	SimdJSONSlowTests     a 16 MB document of 2M boxed floats, and a cap of
	                      old space (OutOfMemory, the VM lives on); skipped
	                      unless the environment has SJ_SLOW

Load them with the groups Core and Tests of BaselineOfSimdJSON (no NeoJSON), then
run the package:

	Metacello new
		baseline: 'SimdJSON';
		repository: 'github://massimo-nocentini/simdjson.st:master/src';
		load: #( 'Core' 'Tests' ).

	pharo --headless X.image --no-default-preferences test --fail-on-failure --fail-on-error SimdJSON-Tests
"
Class {
	#name : 'ManifestSimdJSONTests',
	#superclass : 'PackageManifest',
	#category : 'SimdJSON-Tests-Manifest',
	#package : 'SimdJSON-Tests',
	#tag : 'Manifest'
}
