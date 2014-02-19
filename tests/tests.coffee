fs = require('fs')
async = require('async')

if not QUnit? then QUnit = require('qunit-cli')
q = QUnit

q.module('dockers')
dockers = require('../index')

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
		# [{"docTitle":[],"docAuthors":[],"docDate":[]},[{"Para":[{"Link":[[{"Str":"Test"},"Space",{"Str":"wikilink"}],["",""]]}]}]]
		tree[1][0].Para[0].Link[1][0] = "/pages/Test%20wikilink.md/view"
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



