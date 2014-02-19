_ = require('underscore')

# Author: Casey Grun
# Original Author: John MacFarlane <jgm@berkeley.edu>
# Copyright: (C) 2013 John MacFarlane
# License: BSD3

###
# Functions to aid writing python scripts that process the pandoc
# AST serialized as JSON.
###

###*
 * Walk a tree, applying an action to every object.
 * Returns a modified tree.
###  
walk = (x, action, format, meta) ->
	if _.isArray(x)
		# console.log "Array: "
		# console.log x

		array = []
		for item in x
			if _.isObject(item) and ('t' of item)
				# console.log "Applying action"
				# console.log item
				res = action(item['t'], item['c'], format, meta)

				if res is null or res is undefined
					array.push(walk(item, action, format, meta))
				else if _.isArray(res)
					for z in res
						array.push(walk(z, action, format, meta))
				else
					array.push(walk(res, action, format, meta))
			else
				# console.log "Passing item"
				# console.log item
				array.push(walk(item, action, format, meta))
		return array
	else if _.isObject(x)
		# console.log "Cbject: "
		# console.log x
		
		obj = {}
		for k, v of x
			obj[k] = walk(x[k], action, format, meta)
		return obj
	else
		# console.log "Pass: "
		# console.log x
		

		return x

toJSONFilter = (action) ->
	###
	Converts an action into a filter that reads a JSON-formatted
	pandoc document from stdin, transforms it by walking the tree
	with the action, and returns a new JSON-formatted pandoc document
	to stdout.  The argument is a function action(key, value, format, meta),
	where key is the type of the pandoc object (e.g. 'Str', 'Para'),
	value is the contents of the object (e.g. a string for 'Str',
	a list of inline elements for 'Para'), format is the target
	output format (which will be taken for the first command line
	argument if present), and meta is the document's metadata.
	If the function returns None, the object to which it applies
	will remain unchanged.  If it returns an object, the object will
	be replaced.  If it returns a list, the list will be spliced in to
	the list to which the target object belongs.  (So, returning an
	empty list deletes the object.)
	###

	# TODO:
	process.stdin.resume();
	process.stdin.setEncoding('utf8');

	stdin = ''
	process.stdin.on 'data', (data) ->
		stdin += data

	process.stdin.on 'end', () ->

		doc = JSON.parse(stdin)
		if process.argv.length > 1
			format = process.argv[1]
		else
			format = ""

		altered = walk(doc, action, format, doc[0]['unMeta'])

		# TODO:
		process.stdout.write(JSON.stringify(altered))


toJSONPipe = (action, format) ->
	return (doc, cb) ->
		x = walk(doc, action, format, doc[0]['unMeta'])
		# console.log x
		return cb(null,x)

stringify = (x) ->
	###
	Walks the tree x and returns concatenated string content,
	leaving out all formatting.
	###
	result = []
	go = (key, val, format, meta) ->
		if key == 'Str' 
			result.push(val)
		else if key == 'Code'
			result.push(val[1])
		else if key == 'Math' 
			result.push(val[1])
		else if key == 'LineBreak' 
			result.push(" ")
		else if key == 'Space' 
			result.push(" ")
	walk(x, go, "", {})
	return result.join('')

attributes = (attrs) ->
	###
	Returns an attribute list, constructed from the
	dictionary attrs.
	###
	attrs = attrs or {}
	ident = attrs["id"] or ""
	classes = attrs["classes"] or []
	keyvals = [[x,attrs[x]] for x in attrs when (x != "classes" and x != "id")]
	return [ident, classes, keyvals]

elt = (eltType, numargs) ->
	fun = (args...) ->
		lenargs = args.length
		if lenargs != numargs
			throw (eltType + ' expects ' + numargs + ' arguments, but given ' + lenargs)
		if args.length == 1
			xs = args[0]
		else
			xs = args
		return {'t': eltType, 'c': xs}
	return fun


elements = {}

# Constructors for block elements

Plain            = elements.Plain            = elt('Plain',1)
Para             = elements.Para             = elt('Para',1)
CodeBlock        = elements.CodeBlock        = elt('CodeBlock',2)
RawBlock         = elements.RawBlock         = elt('RawBlock',2)
BlockQuote       = elements.BlockQuote       = elt('BlockQuote',1)
OrderedList      = elements.OrderedList      = elt('OrderedList',2)
BulletList       = elements.BulletList       = elt('BulletList',1)
DefinitionList   = elements.DefinitionList   = elt('DefinitionList',1)
Header           = elements.Header           = elt('Header',3)
HorizontalRule   = elements.HorizontalRule   = elt('HorizontalRule',0)
Table            = elements.Table            = elt('Table',5)
Div              = elements.Div              = elt('Div',2)
Null             = elements.Null             = elt('Null',0)

# Constructors for inline elements

Str              = elements.Str              = elt('Str',1)
Emph             = elements.Emph             = elt('Emph',1)
Strong           = elements.Strong           = elt('Strong',1)
Strikeout        = elements.Strikeout        = elt('Strikeout',1)
Superscript      = elements.Superscript      = elt('Superscript',1)
Subscript        = elements.Subscript        = elt('Subscript',1)
SmallCaps        = elements.SmallCaps        = elt('SmallCaps',1)
Quoted           = elements.Quoted           = elt('Quoted',2)
Cite             = elements.Cite             = elt('Cite',2)
Code             = elements.Code             = elt('Code',2)
Space            = elements.Space            = elt('Space',0)
LineBreak        = elements.LineBreak        = elt('LineBreak',0)
Math             = elements.Math             = elt('Math',2)
RawInline        = elements.RawInline        = elt('RawInline',2)
Link             = elements.Link             = elt('Link',2)
Image            = elements.Image            = elt('Image',2)
Note             = elements.Note             = elt('Note',1)
Span             = elements.Span             = elt('Span',2)


extractMetadata = (doc) ->
	return doc[0]["unMeta"]

extractSection = (identifier, format='html') ->
	(doc, cb) ->
		inSection = false
		sectionLevel = null

		action = (key, value, format, meta) ->
			if not inSection
				# if we find the target header, start outputting
				if key == 'Header'
					[level, [id, classes, attrs], text] = value
					if id == identifier
						inSection = true
						sectionLevel = level
						return null

				# if we didn't find the target header, suppress
				return []
			else if inSection
				# if we find a new header at the same level, stop outputting
				if key == 'Header'
					[level, data, text] = value
					if level == sectionLevel
						inSection = false
						return []

				# otherwise keep outputting 
				return null

		cb(null, walk(doc, action, format, doc[0]['unMeta']))


module.exports =
	walk: walk,
	toJSONFilter: toJSONFilter,
	toJSONPipe: toJSONPipe,
	stringify: stringify,
	attributes: attributes,
	extractSection: extractSection,
	extractMetadata: extractMetadata,
	elements: elements
