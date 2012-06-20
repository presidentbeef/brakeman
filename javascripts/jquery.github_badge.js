/*!
 * jQuery GitHub Badge - v0.3 - 6/18/2012
 * http://www.maverickconceptions.com/2010/09/11/github-badge/
 *
 * Copyright (c) 2010 Lynn Wallenstein
 * Dual licensed under the MIT and GPL licenses.
 * http://www.maverickconceptions.com/about/license/
 */

// avoid javascript errors on browsers that aren't using console.
(function ($) {

    if (!window.console) {
        (function () {
            var names = [
              'log', 'debug', 'info', 'warn', 'error', 'assert',
              'dir', 'dirxml', 'group', 'groupEnd', 'time', 'timeEnd',
              'count', 'trace', 'profile', 'profileEnd'
            ], i;
            window.console = {};
            for (i = 0; i < names.length; i = i + 1) {
              window.console[names[i]] = $.noop;
            }
        }());
    }

    var api_root = "https://api.github.com/", // api v3

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
            '({{public_repos}})',
        '</h1>'].join(''),

    user_info_template = [
        '<img src="{{avatar_url}}" />',
        '{{name}}',
        '<dl>',
            '<dt>Public Repos:</dt>',
            '<dd><a target="_blank" href="http://github.com/{{login}}/repositories">{{public_repos}}</a></dd>',

            '<dt>Followers:</dt>',
            '<dd><a target="_blank" href="http://github.com/{{login}}/followers">{{followers}}</a></dd>',

            '<dt>Following:</dt>',
            '<dd><a target="_blank" href="http://github.com/{{login}}/following">{{following}}</a></dd>',

            '<dt>Public Gists:</dt>',
            '<dd><a target="_blank" href="http://gist.github.com/{{login}}">{{public_gists}}</a></dd>',
        '</dl>'].join(''),

    repo_goto_template = '<a href="http://github.com/{{login}}/repositories">View All {{user_badge_title}} ({{remaining}} More) ... </a>',

    repo_row_template_name = '<li class="ghb_user_repo_item"><a target="_blank" href="{{url}}">{{name}}</a> <div>{{description}}</div></li>',
    repo_row_template_date = '<li data-date="{{pushed_at}}" class="ghb_user_repo_item"><a target="_blank" href="{{url}}">{{name}}</a> <div>{{description}}</div></li>',

    repo_template = [
        '<div class="ghb_badge {{theme}}">',
            '<div class="ghb_badge_header" style="display:none"></div>',
            '<div class="ghb_repo_commits">',
                '<h1>Code Updates</h1>',
                '<ul class="ghb_commit_list">',
                    '<li class="no_records">There are no commits in the {{repo_branch}} branch</li>',
                '</ul>',
            '</div>',
        '</div>'].join(''),

    repo_info_template = [
        '<p>{{description}}</p>',
        '<p><a target="_blank" href="http://github.com/{{full_name}}">http://github.com/{{full_name}}</a></p>',
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
            '<a target="_blank" href="{{html_url}}">{{title}}<span title="{{login}} @ {{created_at}}">by {{login}}</span></a>',
            '<div>{{body}}</div>',
        '</li>'].join(''),

    render = function (template, data) {
        return template.replace(/\{\{([\-_a-z]+)\}\}/g, function (m, key, value) {
          return data[key] || "None";
        });
    },

  buildUser = function(where, options) {
    var
        // URLs
        requestURLUserInfo = api_root + "users/" + options.login + "?callback=?",
        requestURLRepos    = api_root + "users/" + options.login + "/repos?callback=?",

        // Select HTML Elements
        base      = $(where).html(render(user_template, options)),
        header    = base.find(".ghb_badge_header"),
        user_info = base.find(".ghb_badge_user_info"),
        repo_goto = base.find(".ghb_repo_goto"),
        repo_list = base.find(".ghb_repo_list");

    $.getJSON(requestURLUserInfo, function(data){
        var merged = $.extend({}, options, data.data);

        header.html(render(user_header_template, merged));

        if (options.include_github_logo) {
            header.prepend(render(github_logo_template, merged));
        }

        user_info.html(render(user_info_template, merged));

        if (data.public_repos > (options.repo_count) ) {
            merged.remaining = (data.public_repos - options.repo_count);
            repo_goto.html(render(repo_goto_template, merged));
        } else {
            repo_goto.html('<a href="http://github.com/' + options.login + '">' + options.login + ' at GitHub</a>');
        }

        user_info.show();
    });

    $.getJSON(requestURLRepos, function(data){

        if(data.data.length === 0) {
            repo_list.html('<li class="no_records">' + options.login +' Does Not Have Any Repos</li>');
        } else {
            var l, c, rows = [];

            $.each(data.data, function (i, obj) {
                l = render(options.sort_on === "date" ? repo_row_template_date : repo_row_template_name, obj);
                if (obj.fork) { l = l.replace('class="', 'class="ghb_repo_fork '); }
                rows.push( l );
            });

            rows.sort(function(a,b){
                a = a.toLowerCase();
                b = b.toLowerCase();
                if (a === b) { return 0; }
                return a > b ? 1 : -1;
            });
            if (options.sorting !== "ascending" ) {
                rows.reverse();
            }

            c = options.repo_count - 1;
            l = repo_list
              .html(rows.join(''))
              .children()
              .filter(':gt(' + c + ')').hide().end()
              .filter(':first').addClass("firstrepo").end()
              .eq(c).addClass("lastrepo").end();

            if (l.length > c) {
                repo_goto
                    .append('<a href="#" class="ghb_show_more">Show ' + (l.length - c) + ' more</a>')
                    .find('.ghb_show_more').click(function(){
                        l.show();
                        this.innerHTML = '';
                        return false;
                    });
            }
        }
    });
  },

    buildProject = function(where, options) {
        var
        // URLs
        requestURLRepo    = api_root + "repos/" + options.login + "/" + options.repo_name + "?callback=?",
        requestURLIssues  = api_root + "repos/" + options.login + "/" + options.repo_name + "/issues?state=open&callback=?",
        requestURLCommits = api_root + "repos/" + options.login + "/" + options.repo_name + "/commits?callback=?",

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
        var d = data.data;

        header.html('<h1><a target="_blank" href="http://github.com/' + d.full_name + '">' + d.name +'</a></h1>');

        if (options.include_github_logo) {
            header.prepend(render(github_logo_template, options));
        }

        repo_info.html(render(repo_info_template, d));

        goto_issues.html('<a href="http://github.com/' + d.full_name + '/issues">View All Issues</a>');
        goto_commits.html('<a href="http://github.com/' + d.full_name + '/commits">View All Commits</a>');

        repo_info.show();
    });

    $.getJSON(requestURLIssues, function(data){

        if(!data.data) {
            issues_list.html('<li class="no_records">There are no open issues for this repo.</li>');
        } else {
            goto_issues.show();
            var rows = [];
            $.each(data.data, function (i, obj) {
                var merged = $.extend({}, options, obj, obj.user);

                rows.push(render(issues_item, merged));
                if ( i === (options.issue_count - 1 ) ) { return false; }
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
        $.each(data.data, function (i, obj) {
            commits.push('<li><a target="_blank" href="http://github.com/' + options.login + '/' + options.repo_name + '/commit/' +
             obj.sha + '">' + obj.commit.message + '</a></li>');

          if ( i === (options.commit_count - 1) ) { return false; }
        });

        if (options.sorting !== "ascending" ) {
            commits.reverse();
        }

        commit_list
            .html(commits.join(''))
            .children()
                .filter(':first').addClass("firstrepo").end()
                .filter(':last').addClass("lastrepo");

        goto_commits.show();
    });

  };


    $.fn.GitHubBadge = function(options) {
        var context = this;

        // option parsing
        options = jQuery.extend({}, $.fn.GitHubBadge.defaults, options);

        console.group( 'GitHubBadge' );
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
            $(this).find("div").show();
        });
        this.delegate('ul.ghb_repo_list li, ul.ghb_issue_list li', 'mouseleave', function () {
            $(this).find("div").hide();
        });

        console.groupEnd();
        return this; // Don't break the chain
    };


    $.fn.GitHubBadge.defaults = {
        login: null,
        kind: "user", // user or project
        sort_on: "date", // "date" or "name"
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
//        repo_branch: "master", // removed as the API acts weird when a branch is added
        show_issues: true,
        issue_count: "10",
        show_commits: true,
        commit_count: "10"
    };


}(jQuery));

