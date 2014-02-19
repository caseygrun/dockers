fs = require('fs')
async = require('async')

if not QUnit? then QUnit = require('qunit-cli')
q = QUnit

q.module('dockers')
dockers = require('../index')
filters = require('../filters')

q.test 'pipeline',() ->
	text1 = """
	* Metadata: `[[metadata]]`
	* Categories: `[[#category]]`
	* Replacements: `{{replacement}}`
		* Transclusion: `{{>page}}`
		* Templates: `{{template|option1|option2|named_option=value}}`
		* Alternatively:
	"""

	q.stop()
	dockers.pipeline text1, {from: 'markdown', to: 'html'}, [ (tree,cb) ->

		q.ok(tree,'A tree is passed to the first middleware');
		cb(null,tree);

	],(err, html) ->
		q.ok(not err?, 'No error is raised in the pipeline'); if err then console.log err
		q.ok(html?, 'Some HTML is returned')
		q.start()

	# ------------------------------------------------------------------------

	text2 = """
	[Test wikilink]()
	"""

	q.stop()
	dockers.pipeline text2, {from: 'markdown', to: 'html'}, [ (tree,cb) ->
		# [{"unMeta":{}},
		#   [{"t":"Para",
		#     "c":[
		#       {"t":"Link",
		#     	  "c":[
		#     	    [{"t":"Str","c":"Test"},{"t":"Space","c":[]},{"t":"Str","c":"wikilink"}],
		#     	    ["",""]]}]}]]

		# tree[1][0].Para[0].Link[1][0] = "/pages/Test%20wikilink.md/view"
		
		tree[1][0].c[0].c[1][0] = "/pages/Test%20wikilink.md/view"
		cb(null,tree);
	],(err, html) ->
		q.ok(not err?, 'No error is raised in the pipeline'); if err then console.log err
		q.ok(html?, 'Some HTML is returned')
		q.equal(html, '<p><a href="/pages/Test%20wikilink.md/view">Test wikilink</a></p>\n', 'Returned HTML is correct')
		q.start()

q.test 'convert', () ->
	text1 = """
	**Hello world!**
	"""

	text2 = """
	<b>Hello world! Hello world! Hello world! Hello world! Hello world! Hello world! Hello world! Hello world!</b>
	"""

	text3 = """
	* Metadata: `[[metadata]]`
	* Categories: `[[#category]]`
	* Replacements: `{{replacement}}`
		* Transclusion: `{{>page}}`
		* Templates: `{{template|option1|option2|named_option=value}}`
		* Alternatively:
	"""

	text4 = """
	[Test wikilink]()
	"""

	text5 = """
	# Document title


	## Section 1 {.important}

	This is text in section 1

	### Section 1.1 {foo=bar}

	### Section 1.2


	## Section 2

	This is text in section 2
	"""

	text6 = """
	---
	foo: '**bar**'
	baz: bat
	...

	Hello world!
	"""

	q.stop()
	async.series [ 
		(cb) ->
			dockers.convert text1, {}, (err, html) ->
				q.ok(not err?, 'No error is raised in conversion')
				q.ok(html?, 'Some HTML is returned')
				q.equal(html, '<p><strong>Hello world!</strong></p>\n', 'Returned HTML is correct')
				cb(null)
		(cb) ->
			dockers.convert text1, { '--self-contained': true}, (err, html) ->
				q.ok(not err?, 'No error is raised in conversion')
				q.ok(html?, 'Some HTML is returned')
				q.equal(html, 
					"""
					<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
					<html xmlns="http://www.w3.org/1999/xhtml">
					<head>
					  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
					  <meta http-equiv="Content-Style-Type" content="text/css" />
					  <meta name="generator" content="pandoc" />
					  <title></title>
					  <style type="text/css">code{white-space: pre;}</style>
					</head>
					<body>
					<p><strong>Hello world!</strong></p>
					</body>
					</html>\n
					""", 'Returned HTML is correct')
				cb(null)
		(cb) ->
			dockers.convert text2, {from: 'html', to: 'markdown', '--columns': 10}, (err, md) ->
				q.ok(not err?, 'No error is raised in conversion')
				q.ok(md?, 'Some markdown is returned')
				q.equal(md, """
					**Hello
					world!
					Hello
					world!
					Hello
					world!
					Hello
					world!
					Hello
					world!
					Hello
					world!
					Hello
					world!
					Hello
					world!**\n
					""", 'Returned markdown is correct')
				cb(null)
		(cb) ->
			dockers.convert text3, {to: 'json'}, (err, json) ->
				q.ok(not err?, 'No error is raised in conversion')
				q.ok(json?, 'Some JSON is returned')
				cb(null)
		(cb) ->
			dockers.convert text4, {to: 'json'}, (err, json) ->
				q.ok(not err?, 'No error is raised in conversion')
				q.ok(json?, 'Some JSON is returned')
				cb(null)
		(cb) ->
			dockers.convert text5, {to: 'json'}, (err, json) ->
				q.ok(not err?, 'No error is raised in conversion')
				q.ok(json?, 'Some JSON is returned')
				# console.log json
				cb(null)
		(cb) ->
			dockers.convert text6, {to: 'json'}, (err, json) ->
				q.ok(not err?, 'No error is raised in conversion')
				q.ok(json?, 'Some JSON is returned')
				# console.log json
				cb(null)
	], (err) -> q.start()

q.test 'convertFile',() ->
	text1 = """
	* Metadata: `[[metadata]]`
	* Categories: `[[#category]]`
	* Replacements: `{{replacement}}`
		* Transclusion: `{{>page}}`
		* Templates: `{{template|option1|option2|named_option=value}}`
		* Alternatively:
	"""

	q.stop()

	dockers.convertFile text1,{from: 'markdown', to: 'docx'},(err, filename) ->
		q.ok(not err?, 'No error on conversion'); if err then console.log err
		q.ok(filename?, 'Temporary filename generated')
		q.ok(fs.existsSync(filename),'File at filename exists')
		# console.log fs.readFileSync(filename,'utf8')
		q.start()

q.test 'stringify', () ->
	doc1 = [{"unMeta":{}},[{"t":"Para","c":[{"t":"Link","c":[[{"t":"Str","c":"Test"},{"t":"Space","c":[]},{"t":"Str","c":"wikilink"}],["",""]]}]}]]
	doc2 = [{"t":"Para","c":[{"t":"Link","c":[[{"t":"Str","c":"Test"},{"t":"Space","c":[]},{"t":"Str","c":"wikilink"}],["",""]]}]}]
	doc3 = [{"t":"Link","c":[[{"t":"Str","c":"Test"},{"t":"Space","c":[]},{"t":"Str","c":"wikilink"}],["",""]]}]

	string1 = filters.stringify doc1
	string2 = filters.stringify doc2
	string3 = filters.stringify doc3
	
	q.equal(string1, 'Test wikilink')
	q.equal(string2, 'Test wikilink')
	q.equal(string3, 'Test wikilink')

q.test 'toJSONPipe', () ->

	text1 = """
	* Metadata: `[[metadata]]`
	* Categories: `[[#category]]`
	* Replacements: `{{replacement}}`
		* Transclusion: `{{>page}}`
		* Templates: `{{template|option1|option2|named_option=value}}`
		* Alternatively:
	"""

	text2 = """
	[Test wikilink]()
	"""

	caps = (key, value, format, meta) ->
		if key == 'Str'
			return filters.elements.Str(value.toUpperCase())

	wikiLinks = (key, value, format, meta) ->
		if key == 'Link' && value[1][0] == ''
			url = filters.stringify(value[0])
			title = value[1][1]
			return filters.elements.Link(value[0],[url,title])

	q.stop()
	async.series [ 
		(cb) ->
			dockers.pipeline text1, {from: 'markdown', to: 'html'}, [ filters.toJSONPipe(caps, 'markdown') ],(err, html) ->
				q.ok(not err?, 'No error is raised in the pipeline'); if err then console.log err
				q.ok(html?, 'Some HTML is returned')
				q.equal(html, """
					<ul>
					<li>METADATA: <code>[[metadata]]</code></li>
					<li>CATEGORIES: <code>[[#category]]</code></li>
					<li>REPLACEMENTS: <code>{{replacement}}</code>
					<ul>
					<li>TRANSCLUSION: <code>{{&gt;page}}</code></li>
					<li>TEMPLATES: <code>{{template|option1|option2|named_option=value}}</code></li>
					<li>ALTERNATIVELY:</li>
					</ul></li>
					</ul>\n
					""", 'Returned HTML is correct')
				cb(null)
		(cb) ->
			dockers.pipeline text2, {from: 'markdown', to: 'html'}, [ filters.toJSONPipe(wikiLinks, 'markdown') ],(err, html) ->
				q.ok(not err?, 'No error is raised in the pipeline'); if err then console.log err
				q.ok(html?, 'Some HTML is returned')
				q.equal(html, """
					<p><a href="Test wikilink">Test wikilink</a></p>\n
					""", 'Returned HTML is correct')
				cb(null)
	], (err) -> q.start()


q.test 'filters', () ->
	text5 = """
	# Document title


	## Section 1 {.important}

	This is text in section 1

	### Section 1.1 {foo=bar}

	### Section 1.2


	## Section 2

	This is text in section 2
	"""

	q.stop()
	async.series [ 
		(cb) ->
			dockers.pipeline text5, {from: 'markdown', to: 'html'}, [ filters.extractSection('section-1', 'html') ],(err, html) ->
				q.ok(not err?, 'No error is raised in the pipeline'); if err then console.log err
				q.ok(html?, 'Some HTML is returned')
				q.equal(html, """
					<h2 id="section-1" class="important">Section 1</h2>
					<p>This is text in section 1</p>
					<h3 id="section-1.1" foo="bar">Section 1.1</h3>
					<h3 id="section-1.2">Section 1.2</h3>\n
					""", 'Returned HTML is correct')
				cb(null)
		(cb) ->
			metadata_expected = {"foo":{"t":"MetaInlines","c":[{"t":"Strong","c":[{"t":"Str","c":"bar"}]}]},"baz":{"t":"MetaInlines","c":[{"t":"Str","c":"bat"}]}}
			cb(null)

	], (err) -> q.start()

