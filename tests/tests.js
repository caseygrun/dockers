// Generated by CoffeeScript 1.6.3
(function() {
  var QUnit, async, dockers, filters, fs, q;

  fs = require('fs');

  async = require('async');

  if (typeof QUnit === "undefined" || QUnit === null) {
    QUnit = require('qunit-cli');
  }

  q = QUnit;

  q.module('dockers');

  dockers = require('../index');

  filters = require('../filters');

  q.test('pipeline', function() {
    var text1, text2;
    text1 = "* Metadata: `[[metadata]]`\n* Categories: `[[#category]]`\n* Replacements: `{{replacement}}`\n	* Transclusion: `{{>page}}`\n	* Templates: `{{template|option1|option2|named_option=value}}`\n	* Alternatively:";
    q.stop();
    dockers.pipeline(text1, {
      from: 'markdown',
      to: 'html'
    }, [
      function(tree, cb) {
        q.ok(tree, 'A tree is passed to the first middleware');
        return cb(null, tree);
      }
    ], function(err, html) {
      q.ok(err == null, 'No error is raised in the pipeline');
      if (err) {
        console.log(err);
      }
      q.ok(html != null, 'Some HTML is returned');
      return q.start();
    });
    text2 = "[Test wikilink]()";
    q.stop();
    return dockers.pipeline(text2, {
      from: 'markdown',
      to: 'html'
    }, [
      function(tree, cb) {
        tree[1][0].c[0].c[1][0] = "/pages/Test%20wikilink.md/view";
        return cb(null, tree);
      }
    ], function(err, html) {
      q.ok(err == null, 'No error is raised in the pipeline');
      if (err) {
        console.log(err);
      }
      q.ok(html != null, 'Some HTML is returned');
      q.equal(html, '<p><a href="/pages/Test%20wikilink.md/view">Test wikilink</a></p>\n', 'Returned HTML is correct');
      return q.start();
    });
  });

  q.test('convert', function() {
    var text1, text2, text3, text4, text5, text6;
    text1 = "**Hello world!**";
    text2 = "<b>Hello world! Hello world! Hello world! Hello world! Hello world! Hello world! Hello world! Hello world!</b>";
    text3 = "* Metadata: `[[metadata]]`\n* Categories: `[[#category]]`\n* Replacements: `{{replacement}}`\n	* Transclusion: `{{>page}}`\n	* Templates: `{{template|option1|option2|named_option=value}}`\n	* Alternatively:";
    text4 = "[Test wikilink]()";
    text5 = "# Document title\n\n\n## Section 1 {.important}\n\nThis is text in section 1\n\n### Section 1.1 {foo=bar}\n\n### Section 1.2\n\n\n## Section 2\n\nThis is text in section 2";
    text6 = "---\nfoo: '**bar**'\nbaz: bat\n...\n\nHello world!";
    q.stop();
    return async.series([
      function(cb) {
        return dockers.convert(text1, {}, function(err, html) {
          q.ok(err == null, 'No error is raised in conversion');
          q.ok(html != null, 'Some HTML is returned');
          q.equal(html, '<p><strong>Hello world!</strong></p>\n', 'Returned HTML is correct');
          return cb(null);
        });
      }, function(cb) {
        return dockers.convert(text1, {
          '--self-contained': true
        }, function(err, html) {
          q.ok(err == null, 'No error is raised in conversion');
          q.ok(html != null, 'Some HTML is returned');
          q.equal(html, "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n<html xmlns=\"http://www.w3.org/1999/xhtml\">\n<head>\n  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n  <meta http-equiv=\"Content-Style-Type\" content=\"text/css\" />\n  <meta name=\"generator\" content=\"pandoc\" />\n  <title></title>\n  <style type=\"text/css\">code{white-space: pre;}</style>\n</head>\n<body>\n<p><strong>Hello world!</strong></p>\n</body>\n</html>\n", 'Returned HTML is correct');
          return cb(null);
        });
      }, function(cb) {
        return dockers.convert(text2, {
          from: 'html',
          to: 'markdown',
          '--columns': 10
        }, function(err, md) {
          q.ok(err == null, 'No error is raised in conversion');
          q.ok(md != null, 'Some markdown is returned');
          q.equal(md, "**Hello\nworld!\nHello\nworld!\nHello\nworld!\nHello\nworld!\nHello\nworld!\nHello\nworld!\nHello\nworld!\nHello\nworld!**\n", 'Returned markdown is correct');
          return cb(null);
        });
      }, function(cb) {
        return dockers.convert(text3, {
          to: 'json'
        }, function(err, json) {
          q.ok(err == null, 'No error is raised in conversion');
          q.ok(json != null, 'Some JSON is returned');
          return cb(null);
        });
      }, function(cb) {
        return dockers.convert(text4, {
          to: 'json'
        }, function(err, json) {
          q.ok(err == null, 'No error is raised in conversion');
          q.ok(json != null, 'Some JSON is returned');
          return cb(null);
        });
      }, function(cb) {
        return dockers.convert(text5, {
          to: 'json'
        }, function(err, json) {
          q.ok(err == null, 'No error is raised in conversion');
          q.ok(json != null, 'Some JSON is returned');
          return cb(null);
        });
      }, function(cb) {
        return dockers.convert(text6, {
          to: 'json'
        }, function(err, json) {
          q.ok(err == null, 'No error is raised in conversion');
          q.ok(json != null, 'Some JSON is returned');
          return cb(null);
        });
      }
    ], function(err) {
      return q.start();
    });
  });

  q.test('convertFile', function() {
    var text1;
    text1 = "* Metadata: `[[metadata]]`\n* Categories: `[[#category]]`\n* Replacements: `{{replacement}}`\n	* Transclusion: `{{>page}}`\n	* Templates: `{{template|option1|option2|named_option=value}}`\n	* Alternatively:";
    q.stop();
    return dockers.convertFile(text1, {
      from: 'markdown',
      to: 'docx'
    }, function(err, filename) {
      q.ok(err == null, 'No error on conversion');
      if (err) {
        console.log(err);
      }
      q.ok(filename != null, 'Temporary filename generated');
      q.ok(fs.existsSync(filename), 'File at filename exists');
      return q.start();
    });
  });

  q.test('stringify', function() {
    var doc1, doc2, doc3, string1, string2, string3;
    doc1 = [
      {
        "unMeta": {}
      }, [
        {
          "t": "Para",
          "c": [
            {
              "t": "Link",
              "c": [
                [
                  {
                    "t": "Str",
                    "c": "Test"
                  }, {
                    "t": "Space",
                    "c": []
                  }, {
                    "t": "Str",
                    "c": "wikilink"
                  }
                ], ["", ""]
              ]
            }
          ]
        }
      ]
    ];
    doc2 = [
      {
        "t": "Para",
        "c": [
          {
            "t": "Link",
            "c": [
              [
                {
                  "t": "Str",
                  "c": "Test"
                }, {
                  "t": "Space",
                  "c": []
                }, {
                  "t": "Str",
                  "c": "wikilink"
                }
              ], ["", ""]
            ]
          }
        ]
      }
    ];
    doc3 = [
      {
        "t": "Link",
        "c": [
          [
            {
              "t": "Str",
              "c": "Test"
            }, {
              "t": "Space",
              "c": []
            }, {
              "t": "Str",
              "c": "wikilink"
            }
          ], ["", ""]
        ]
      }
    ];
    string1 = filters.stringify(doc1);
    string2 = filters.stringify(doc2);
    string3 = filters.stringify(doc3);
    q.equal(string1, 'Test wikilink');
    q.equal(string2, 'Test wikilink');
    return q.equal(string3, 'Test wikilink');
  });

  q.test('toJSONPipe', function() {
    var caps, text1, text2, wikiLinks;
    text1 = "* Metadata: `[[metadata]]`\n* Categories: `[[#category]]`\n* Replacements: `{{replacement}}`\n	* Transclusion: `{{>page}}`\n	* Templates: `{{template|option1|option2|named_option=value}}`\n	* Alternatively:";
    text2 = "[Test wikilink]()";
    caps = function(key, value, format, meta) {
      if (key === 'Str') {
        return filters.elements.Str(value.toUpperCase());
      }
    };
    wikiLinks = function(key, value, format, meta) {
      var title, url;
      if (key === 'Link' && value[1][0] === '') {
        url = filters.stringify(value[0]);
        title = value[1][1];
        return filters.elements.Link(value[0], [url, title]);
      }
    };
    q.stop();
    return async.series([
      function(cb) {
        return dockers.pipeline(text1, {
          from: 'markdown',
          to: 'html'
        }, [filters.toJSONPipe(caps, 'markdown')], function(err, html) {
          q.ok(err == null, 'No error is raised in the pipeline');
          if (err) {
            console.log(err);
          }
          q.ok(html != null, 'Some HTML is returned');
          q.equal(html, "<ul>\n<li>METADATA: <code>[[metadata]]</code></li>\n<li>CATEGORIES: <code>[[#category]]</code></li>\n<li>REPLACEMENTS: <code>{{replacement}}</code>\n<ul>\n<li>TRANSCLUSION: <code>{{&gt;page}}</code></li>\n<li>TEMPLATES: <code>{{template|option1|option2|named_option=value}}</code></li>\n<li>ALTERNATIVELY:</li>\n</ul></li>\n</ul>\n", 'Returned HTML is correct');
          return cb(null);
        });
      }, function(cb) {
        return dockers.pipeline(text2, {
          from: 'markdown',
          to: 'html'
        }, [filters.toJSONPipe(wikiLinks, 'markdown')], function(err, html) {
          q.ok(err == null, 'No error is raised in the pipeline');
          if (err) {
            console.log(err);
          }
          q.ok(html != null, 'Some HTML is returned');
          q.equal(html, "<p><a href=\"Test wikilink\">Test wikilink</a></p>\n", 'Returned HTML is correct');
          return cb(null);
        });
      }
    ], function(err) {
      return q.start();
    });
  });

  q.test('filters', function() {
    var text5;
    text5 = "# Document title\n\n\n## Section 1 {.important}\n\nThis is text in section 1\n\n### Section 1.1 {foo=bar}\n\n### Section 1.2\n\n\n## Section 2\n\nThis is text in section 2";
    q.stop();
    return async.series([
      function(cb) {
        return dockers.pipeline(text5, {
          from: 'markdown',
          to: 'html'
        }, [filters.extractSection('section-1', 'html')], function(err, html) {
          q.ok(err == null, 'No error is raised in the pipeline');
          if (err) {
            console.log(err);
          }
          q.ok(html != null, 'Some HTML is returned');
          q.equal(html, "<h2 id=\"section-1\" class=\"important\">Section 1</h2>\n<p>This is text in section 1</p>\n<h3 id=\"section-1.1\" foo=\"bar\">Section 1.1</h3>\n<h3 id=\"section-1.2\">Section 1.2</h3>\n", 'Returned HTML is correct');
          return cb(null);
        });
      }, function(cb) {
        var metadata_expected;
        metadata_expected = {
          "foo": {
            "t": "MetaInlines",
            "c": [
              {
                "t": "Strong",
                "c": [
                  {
                    "t": "Str",
                    "c": "bar"
                  }
                ]
              }
            ]
          },
          "baz": {
            "t": "MetaInlines",
            "c": [
              {
                "t": "Str",
                "c": "bat"
              }
            ]
          }
        };
        return cb(null);
      }
    ], function(err) {
      return q.start();
    });
  });

}).call(this);
