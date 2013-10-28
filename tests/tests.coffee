fs = require('fs')

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
	dockers.pipeline text1,'markdown','html', [], [ (tree,cb) ->

		q.ok(tree,'A tree is passed to the first middleware');
		cb(null,tree);

	],(err, html) ->
		q.ok(not err?, 'No error is raised in the pipeline')
		q.ok(html?, 'Some HTML is returned')
		q.start()

	# ------------------------------------------------------------------------

	text2 = """
	[Test wikilink]()
	"""

	q.stop()
	dockers.pipeline text2,'markdown','html', [], [ (tree,cb) ->
		# [{"docTitle":[],"docAuthors":[],"docDate":[]},[{"Para":[{"Link":[[{"Str":"Test"},"Space",{"Str":"wikilink"}],["",""]]}]}]]
		console.log tree[1]
		tree[1][0].Para[0].Link[1][0] = "/pages/Test%20wikilink.md/view"
		cb(null,tree);
	],(err, html) ->
		q.ok(not err?, 'No error is raised in the pipeline')
		q.ok(html?, 'Some HTML is returned')
		q.equal(html, '<p><a href="/pages/Test%20wikilink.md/view">Test wikilink</a></p>\n', 'Returned HTML is correct')
		q.start()


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

	dockers.convertFile text1,'markdown','docx',[],(err, filename) ->
		q.ok(not err?, 'No error on conversion'); if err then console.log err
		q.ok(filename?, 'Temporary filename generated')
		q.ok(fs.existsSync(filename),'File at filename exists')
		# console.log fs.readFileSync(filename,'utf8')
		q.start()



