"
SimdJSON-FFI - SimdJSONReader and SimdJSONWriter without the SimdJSONPlugin, through the FFI of the image

On a VM without the plugin, SimdJSONReader and SimdJSONWriter go through SimdJSONLibrary (SimdJSONReader class>>fallback, backend answers #ffi): libSimdJSONFFI, the engine of the plugin built as a library of its own (FEATURE_SIMDJSON_FFI of https://github.com/massimo-nocentini/pharo-vm).

- Reading: the library parses with simdjson and writes the value as a tape of 8-byte slots, and SimdJSONTapeDecoder makes the objects in the image.
- Writing: SimdJSONTapeEncoder walks the value in the image, as primitiveWrite walks it, and writes a tape of it, from which the library writes the JSON with the plugin's own code; the objects the walk leaves out (holes) are written by SimdJSONWriter, as with the plugin.

They answer the same values and the same text, with the same errors, faster than NeoJSON and slower than the plugin, which walks the objects in C.  With the plugin, this package is not used.

Put the library next to the VM or the image, or give its path:

	SimdJSONLibrary libraryPath: '/path/to/libSimdJSONFFI.so'
"
Class {
	#name : 'ManifestSimdJSONFFI',
	#superclass : 'PackageManifest',
	#category : 'SimdJSON-FFI-Manifest',
	#package : 'SimdJSON-FFI',
	#tag : 'Manifest'
}
