/*!
 * jQuery GitHub Badge - v0.2.3 - 10/13/2010
 * http://www.maverickconceptions.com/2010/09/11/github-badge/
 * 
 * Copyright (c) 2010 Lynn Wallenstein
 * Dual licensed under the MIT and GPL licenses.
 * http://www.maverickconceptions.com/about/license/
 */

// avoid javascript errors on browsers that aren't using FireBug.
(function ($) {
    function relative_time(time_value) {
      var parsed_date = Date.parse(time_value);
      var relative_to = (arguments.length > 1) ? arguments[1] : new Date();
      var delta = parseInt((relative_to.getTime() - parsed_date) / 1000, 10);
      var r = '';
      if (delta < 60) {
        r = delta + ' seconds ago';
      } else if(delta < 120) {
        r = 'a minute ago';
      } else if(delta < (45*60)) {
        r = (parseInt(delta / 60, 10)).toString() + ' minutes ago';
      } else if(delta < (2*60*60)) {
        r = 'an hour ago';
      } else if(delta < (24*60*60)) {
        r = '' + (parseInt(delta / 3600, 10)).toString() + ' hours ago';
      } else if(delta < (48*60*60)) {
        r = 'a day ago';
      } else {
        r = (parseInt(delta / 86400, 10)).toString() + ' days ago';
      }
      return 'about ' + r;
    }

    if (!window.console || !console.firebug) {
        (function () {
            var names = [
              'log', 'debug', 'info', 'warn', 'error', 'assert',
              'dir', 'dirxml', 'group', 'groupEnd', 'time', 'timeEnd',
              'count', 'trace', 'profile', 'profileEnd'
            ], i = 0;
            window.console = {};
            for (; i < names.length; i = i + 1) {
              window.console[names[i]] = $.noop;
            }
        }());
    }
  
    var api_root = "http://github.com/api/v2/json/",

    github_logo_template = '<a target="_blank" href="http://github.com"><img src="{{image_path}}ghb_logo.png" alt="GitHub"></a>',

    user_template = [
        '<div class="ghb_badge {{theme}}">',
            '<div class="ghb_badge_header"></div>',
            '<div class="ghb_user_nav">',
                '<a class="ghb_user_info_nav chosen" rel="ghb_badge_user_info" href="#">User Info</a>',
                '<a class="ghb_user_repo_nav"        rel="ghb_badge_user_repos" href="#">Repos</a>',
            '</div>',
            '<div class="ghb_badge_user_info" style="display:none;">',
                '<h2>User Info</h2>',
                '<div></div>',
            '</div>',
            '<div class="ghb_badge_user_repos" style="display:none;">',
                '<h2>Public {{user_badge_title}}</h2>',
                '<ul class="ghb_repo_list"></ul>',
                '<div class="ghb_repo_goto"></div>',
            '</div>',
        '</div>'].join(''),

    user_header_template = [
        '<h1>',
            '<a target="_blank" href="http://github.com/{{login}}">{{login}}\'s GitHub</a> ',
            '({{public_repo_count}})',
        '</h1>'].join(''),

    user_info_template = [
        '<img src="http://www.gravatar.com/avatar/{{gravatar_id}}" />',
        '{{name}}',
        '<dl>',
            '<dt>Public Repos:</dt>',
            '<dd><a target="_blank" href="http://github.com/{{login}}/repositories">{{public_repo_count}}</a></dd>',

            '<dt>Followers:</dt>',
            '<dd><a target="_blank" href="http://github.com/{{login}}/followers">{{followers_count}}</a></dd>',

            '<dt>Following:</dt>',
            '<dd><a target="_blank" href="http://github.com/{{login}}/following">{{following_count}}</a></dd>',

            '<dt>Public Gists:</dt>',
            '<dd><a target="_blank" href="http://gist.github.com/{{login}}">{{public_gist_count}}</a></dd>',
        '</dl>'].join(''),

    repo_goto_template = '<a href="http://github.com/{{login}}/repositories">View All {{user_badge_title}} ({{remaining}} More) ... </a>',
    
    repo_row_template = '<li class="ghb_user_repo_item"><a target="_blank" href="{{url}}">{{name}}</a> <div>{{description}}</div></li>',

    repo_template = [
        '<div class="ghb_badge {{theme}}">',
            '<div class="ghb_badge_header"></div>',
            '<div class="ghb_repo_commits">',
                '<h1>Code Updates</h1>',
                '<ul class="ghb_commit_list">',
                    '<li class="no_records">There are no commits in the {{repo_branch}} branch</li>',
                '</ul>',
                '<div class="ghb_repo_goto_commits"></div>',
            '</div>',
        '</div>'].join(''),

    repo_info_template = [
        '<p>{{description}}</p>',
        '<p><a target="_blank" href="{{url}}">{{url}}</a></p>',
        '<dl class="repo_info_list">',
            '<dt>Watchers:</dt>',
            '<dd>{{watchers}}</dd>',
            '<dt>Created:</dt>',
            '<dd>{{created_at}}</dd>',
            '<dt>Last Updated:</dt>',
            '<dd>{{pushed_at}}</dd>',
        '</dl>'].join(''),
        
    issues_item = [
        '<li>',
            '<a target="_blank" href="http://github.com/{{login}}/{{repo_name}}/issues#issue/{{number}}">{{title}}<span title="{{user}} @ {{created_at}}">by {{user}}</span></a>',
            '<div>{{body}}</div>',
        '</li>'].join(''),

    render = function (template, data) {
        return template.replace(/\{\{([-_a-z]+)\}\}/g, function (m, key, value) {
          return data[key] ? data[key] : "None";
        });
    },

  buildUser = function(where, options) {
    var 
        // URLs
        requestURLUserInfo = api_root + "user/show/" + options.login + "?callback=?",
        requestURLRepos    = api_root + "repos/show/" + options.login + "?callback=?",
    
        // Select HTML Elements
        base      = $(where).html(render(user_template, options)),
        header    = base.find(".ghb_badge_header"),
        user_info = base.find(".ghb_badge_user_info"),
        repo_goto = base.find(".ghb_repo_goto"),
        repo_list = base.find(".ghb_repo_list");
    
    $.getJSON(requestURLUserInfo, function(data){
        ////console.log(data);
        var merged = $.extend({}, options, data.user);

        header.html(render(user_header_template, merged));
        
        if (options.include_github_logo) {
            header.prepend(render(github_logo_template, merged));
        }

        user_info.html(render(user_info_template, merged));
        
        if (data.user.public_repo_count > (options.repo_count - 1) ) {
            merged.remaining = (data.user.public_repo_count - options.repo_count);
            repo_goto.html(render(repo_goto_template, merged));
        } else {
            repo_goto.html('<a href="http://github.com/' + options.login + '">' + options.login + ' at GitHub</a>');
        }
        
        user_info.show();
    });      
    
    $.getJSON(requestURLRepos, function(data){
        //console.log(data);
        if(data.length === 0) {
            repo_list.html('<li class="no_records">' + options.login +' Does Not Have Any Repos</li>');
        } else {
            var rows = [];
            
            $.each(data.repositories, function (i, obj) {
                rows.push(render(repo_row_template, obj));
                if ( i === (options.repo_count - 1) ) return false;
            });
            
            if (options.sorting !== "ascending" ) {
                rows.reverse();
            }
            
            repo_list
              .html(rows.join(''))
              .children()
                .filter(':first').addClass("firstrepo").end()
                .filter(':last').addClass("lastrepo");
                            
        }
    });   
  },

    buildProject = function(where, options) {
        var
        // URLs
        requestURLRepo    = api_root +   "repos/show/" + options.login + "/" + options.repo_name + "?callback=?",
        requestURLIssues  = api_root +  "issues/list/" + options.login + "/" + options.repo_name + "/open?callback=?",
        requestURLCommits = api_root + "commits/list/" + options.login + "/" + options.repo_name + "/" + options.repo_branch + "?callback=?",
        
        // Select HTML Elements
        base         = $(where).html(render(repo_template, options)),
        header       = base.find('.ghb_badge_header'),
        repo_info    = base.find('.ghb_repo_info'),
        issues_list  = base.find('.ghb_issue_list'),
        goto_issues  = base.find('.ghb_repo_goto_issues').hide(),
        goto_commits = base.find('.ghb_repo_goto_commits').hide(),
        commit_list  = base.find('.ghb_commit_list'),
        no_commits   = commit_list.find('.no_commits');
    
    $.getJSON(requestURLRepo, function(data){

        header.html('');
        
        if (options.include_github_logo) {
            header.prepend(render(github_logo_template, options));
        }
        
        repo_info.html(render(repo_info_template, data.repository));
        
        goto_issues.html('<a href="' + data.repository.url + '/issues">View All Issues</a>');
        goto_commits.html('<a href="' + data.repository.url + '/commits/' + options.repo_branch +'">View All Commits</a>');
        
        repo_info.show();
    });
    
    $.getJSON(requestURLIssues, function(data){
        if(data.issues.length === 0) {
            issues_list.html('<li class="no_records">There are no open issues for this repo.</li>');
        } else {
            goto_issues.show();
            var rows = [];
            $.each(data.issues, function (i, obj) {
                var merged = $.extend({}, options, obj);
                
                rows.push(render(issues_item, merged));
                if ( i === (options.issue_count - 1 ) ) return false;
            });
            
            if (options.sorting !== "ascending" ) {
                rows.reverse();
            }
            
            issues_list
                .html(rows.join(''))
                .children()
                    .filter(':first').addClass("firstrepo").end()
                    .filter(':last').addClass("lastrepo");
                    
        }
    });
    
    $.getJSON(requestURLCommits, function(data){
        var commits = [];
        $.each(data.commits, function (i, obj) {
            commits.push('<li><a target="_blank" href="https://github.com'+ obj.url + '">' + obj.message + '</a><br>   ' + relative_time(obj.committed_date) + '</li>');

            if ( i === (options.commit_count - 1) ) return false;
        });
        
        if (options.sorting !== "ascending" ) {
            commits.reverse();
        }
        
        commit_list
            .html(commits.join(''))
            .children()
                .filter(':first').addClass("firstrepo").end()
                .filter(':last').addClass("lastrepo");
                
    }); 

  };
  

    $.fn.GitHubBadge = function(options) {
        var context = this;
        
        // option parsing
        options = jQuery.extend({}, $.fn.GitHubBadge.defaults, options);
        
				console.log( "Options parsed as: %o", options );
    
        // sanity checks.
        if (!options.login) {
					console.log( "%s", options.login + " is undefined, not doing anything." );
          return this;
        }
    
        // dispatch
        if (options.kind === "user") {
            buildUser(this, options);
        } else if (options.kind === "project") {
            if (!options.repo_name) {
							console.log( "%s", options.repo_name + " is undefined, not doing anything." );
              return this;
            }
            buildProject(this, options);
        }
        
        this.delegate('.ghb_user_nav a, .ghb_repo_nav a', 'click', function (e) {
            e.preventDefault();
            var old_panel = context.find('.chosen').removeClass('chosen').attr('rel'),
                new_panel = $(this).addClass('chosen').attr('rel');
        
            context.find('.' + old_panel).hide();
            context.find('.' + new_panel)[options.animate_style === "slide" ? "slideDown" : "show"]();
        });
        
        this.delegate('ul.ghb_repo_list li, ul.ghb_issue_list li', 'mouseenter', function () {
						$(this).find("div").show()
        });        
        this.delegate('ul.ghb_repo_list li, ul.ghb_issue_list li', 'mouseleave', function () {
						$(this).find("div").hide()
        });        
            
        return this; // Don't break the chain            
    };
    
  
    $.fn.GitHubBadge.defaults = {
        login: null,
        kind: "user", // user or project
        sorting: "ascending", // ascending or descending for repos (user badge) and issues (project badge)
        theme: "github", // adds value as class for entire badge
        include_github_logo: true, // show a lil love
        image_path: "images/", 
        animate_style: "slide", //slideDown or show
        
        // User Badge Options
        user_badge_title: "Repositories",
        repo_count: "10",
        show_repos: true, 
        
        // Repo Badge Options 
        repo_name: null,
        repo_branch: "master",
        show_issues: true,
        issue_count: "10",
        show_commits: true,
        commit_count: "10"
    };
    
    
}(jQuery));

