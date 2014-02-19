_ = require('underscore')
async = require('async')
tmp = require('tmp')


pth = require('path')
spawn = require('child_process').spawn


formats = {
	'pdf': [null, []]
}

defaultOptions = {
	'from': 'markdown'
	'to': 'html'
}

getFormatOptions = (to, opt) ->
	if formats[to]
		opt.concat(formats[to][1])
		to = formats[to][0]
	[to, opt]

buildArguments = (opt) ->
	args = []
	for key, value of opt
		if key == 'to' then key = '-t'
		if key == 'from' then key = '-f'
		if key == 'out' then key = '-o'

		if value && value != true then args.push(key); args.push(value)
		else args.push(key)
	return args

###*
 * Invokes Pandoc with the given source text and array of command-line options
 * @param  {String} src Input text
 * @param  {String[]} args Command line options
 * @param  {Function} callback Callback to be executed upon completion
 * @param  {Error} callback.err Error if one occurs
 * @param  {String} callback.result Output text
###
runPandoc = (src, args, callback) ->
	
	do (src, args, callback) -> 
		pandoc = spawn('pandoc', args);

		res = '';
		err = '';

		pandoc.stdout.setEncoding('utf8');
		pandoc.stderr.setEncoding('utf8');
		pandoc.stdout.on('data',(data) -> res += data; null )
		pandoc.stderr.on('data',(data) -> err += data; null )

		pandoc.on 'close',(code) ->
			if code != 0 
				return callback(new Error('pandoc exited with code '+code+'. ' + (err || '') ));
			else if err 
				return callback(new Error(err));
			else
				callback(null, res)
				null

		pandoc.stdout.resume();
		pandoc.stderr.resume();

		pandoc.stdin.end(src, 'utf8');

pandoc = (src, opt, cb) ->
	args = buildArguments(opt);
	runPandoc(src, args, cb);

###*
 * Invokes pandoc to convert the input text `src` from one format to another, with optional arguments `opt`
 * @param  {String} src Input text
 * @param  {String} from Input format (e.g. `markdown`, `html`, etc. )
 * @param  {String} to Output format (e.g. `markdown`, `html`, `latex`, etc.)
 * @param  {String[]} opt Array of command line options to be passed to Pandoc
 * @param  {Function} callback Callback to be executed upon completion
 * @param  {Error} callback.err Error if one occurs
 * @param  {String} callback.result Output text
###
pdc = (src, from, to, opt, cb) ->
	if not cb?
		cb = opt
		opt = null

	args = ['-f', from];
	[to, opt] = getFormatOptions(to,opt)

	if to? then args = args.concat(['-t', to])
	if opt? then args = args.concat(opt)

	runPandoc(src, args, cb)


pdcToFile = (src, from, to, out, opt, cb) ->
	if not cb?
		cb = opt
		opt = null

	args = ['-f', from];
	[to, opt] = getFormatOptions(to,opt)

	if to? then args = args.concat(['-t', to])
	if out? then args = args.concat(['-o', out])
	if opt? then args = args.concat(opt)

	runPandoc(src, args, cb)


###*
 * Runs a pipeline of middleware to process JSON trees from Pandoc
 * @param  {String} text Input text
 * @param  {Object} options Hash of options to be passed to Pandoc
 * 
 * @param  {Function[]} middleware 
 * Array of functions to be called between the input and output.
 * Each function will be passed two arguments:
 * 
 *     - `currentTree`: a JSON array containing the current Pandoc document tree, 
 *        as modified by previous middleware
 *     - `next(err, updatedTree)`: a callback to be called upon completion of the present middleware
 * 
 * Each middleware function should modify the passed `currentTree` as suitable, then call `next` 
 * with either an `Error` or the modified tree. This modified tree will be passed to subsequent 
 * middleware, and so forth.
 *
 * @param  {Function} callback Callback to be executed upon completion
 * @param {Error} callback.err Error if one occurs
 * @param {String} callback.output Output text
 ###
pipeline = (text, options={}, middleware, callback) ->
	_.defaults(options, defaultOptions)

	from = options.from
	to = options.to

	delete options.from
	delete options.to

	# function to be run before any of the middleware
	pre = (cb) -> 

		# execute pandoc once to generate a JSON parse-tree of the input text
		pandoc text, { from: from , to: 'json' },(err, tree) ->
			if err 
				cb(err) 
			else 
				# attempt to parse the tree (as text) to an object
				try
					t = JSON.parse(tree);
				catch e  
					return cb(e)
				cb(null,t);

	# function to be run after all the middleware
	post = (tree,cb) -> 

		# dump final tree to string
		finalText = JSON.stringify(tree)

		# send final tree to pandoc to generate output text
		pandoc finalText, _.extend({ from: 'json', to: to }, options), cb

	# generate chain of functions to be executed by async.waterfall, starting
	# with `pre` and ending with `post`.
	chain = ([ pre ]).concat(middleware).concat([ post ]);
	async.waterfall chain, callback

###*
 * Generates a path to a temporary file, optionally touching that file
 * @param  {Mixed} data If not null, the file will be created on disk. Otherwise, only a file path will be returned
 * @param  {Function} cb Callback to be passed the new filename
 * @param {Error} cb.err Error if one occurs while creating the new file
 * @param {String} cb.filename Path to the new file
###
tempFile = (data,cb) ->
	if !cb? 
		cb = data; data = null;

	if data 
		tmp.file(cb)
	else 
		tmp.tmpName(cb)

module.exports = me =

	pipeline: (text, options, middleware, callback) ->
		pipeline(text, options, middleware, callback)

	pipelineFile: (text, from, to, options, middleware, callback) ->
		# pipeline(text, from, to, options, middleware, me.convertFile, callback)

	convert: (text, options={}, callback) ->
		pandoc(text, options, callback)
		# callback(text)
	
	convertFile: (text, options, callback) ->
		tempFile (err,outputFile) -> 
			if err then return callback(err)

			pandoc text, _.extend({ 'out': outputFile }, options), (err, data) -> 
				callback(err, outputFile)
