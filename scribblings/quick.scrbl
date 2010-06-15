#lang scribble/doc

@(require scribble/eval
          scribble/manual
          (planet cce/scheme:6:0/scribble)
          (for-label scheme/base
                     "../main.ss"))

@title[#:tag "quick"]{Quick Start}

This section provides a worked example of using Dispatch to set up the blog described earlier. Some details are skipped over here: see the @secref["api"] for more information on the macros and procedures used.

@section{Create the site}

The first step is to create a @italic{site} definition using @scheme[define-site]. Create a directory called @scheme{blog} and in it create a file called @scheme{blog/site.ss}. Edit this file and type in the following:

@(schememod scheme/base
  (require (planet untyped/dispatch))

  (define-site blog
    ([("/") index]
     [("/posts/" (string-arg)) review-post]
     [("/archive/" (integer-arg) "/" (integer-arg))
      review-archive]))

  (provide (site-out blog)))

Now that the site has been defined we just need a servlet to create a working web application. We will simplify the creation of our servlet by using the @scheme[serve/dispatch] procedure. Create a file called @scheme{blog/main.ss}, edit it and type in the following:

@(schememod scheme/base

  (require (planet untyped/dispatch)
           "site.ss")

  (serve/dispatch blog))

@scheme[serve/dispatch] starts a web server and populates it with a single servlet that dispatches to @scheme[blog] whenever it receives an HTTP request. Arguments are pretty much the same as for @scheme[serve/servlet].

We should now be able to test the site. Run this application in DrScheme and visit @tt{http://localhost:8000/} in your web browser. You should see an error page saying something like ``@italic{Controller not defined}''. Also try @scheme{http://localhost:8000/posts/hello-world} and @scheme{http://localhost:8000/archive/2008/02}.

@scheme[serve/dispatch] provides a default 404 handler for use when it cannot find a matching rule. Test this by going to @scheme{http://localhost:8000/foo} in your browser.

@section{Define some controllers}

The @italic{Controller not defined} error pages above are appearing because there are no @scheme[define-controller] statements for our controllers. We will write a @scheme[define-controller] statement for @scheme[review-post] now. Create a directory @scheme{blog/controllers} and in it a file called @scheme{blog/controllers/posts.ss}. Edit this file and type in the following:

@schememod[scheme/base

  (require (planet untyped/dispatch)
           "../site.ss")
  
  (code:comment "request string -> html-response") 
  (define-controller (review-post request slug)
    `(html (head (title ,slug))
           (body (h1 "You are viewing " ,(format "~s" slug))
                 (p "And now for some content..."))))]

We need to make sure @scheme{posts.ss} gets executed so that this definition gets loaded into @scheme[blog]. To do this, add an extra clause to the @scheme[require] statement in @scheme{main.ss} so that it reads:

@(schemeblock
  (require (planet untyped/dispatch)
           "site.ss"
           "controllers/posts.ss"))

Now re-run the application and go to @scheme{http://localhost:8000/posts/hello-world} in your browser. You should see the web page we just created.

@section{Insert links from one controller to another}

Now that we are able to write controllers and dispatch to them, we need to know how to create links from one controller to another. Dispatch lets us do this without having to remember the URL structure of the site. Return to @scheme{blog/controllers/posts.ss} and add the following code for the @scheme[index] controller:

@(schemeblock
  (code:comment "(listof string)")
  (define slugs (list "post1" "post2" "post3"))

  (code:comment "request -> html-response") 
  (define-controller (index request)
    `(html
      (head (title "Index"))
      (body
       (h1 "Index")
       (ul ,@(for/list ([slug (in-list slugs)])
               `(li ,(controller-link
                      review-post
                      slug
                      #:body (format "View ~a" slug)))))))))

In this code, the @scheme[index] controller is generating a list of posts using Dispatch's @scheme[controller-link] procedure.  @scheme[controller-link] takes as its arguments the controller to link to and the values of any URL pattern arguments. A mandatory @scheme[#:body] keyword argument specifies the body of the link.

Note that @scheme[review-post] is being provided from the @scheme[define-site] statement @scheme{site.ss}. We can easily write @scheme[review-post] in a separate different module without creating a cyclic dependency with @scheme[index].

Re-run @scheme{main.ss} and revisit the index page in your browser. You should see a list of three links. Inspect the HTML source of the page and notice that the links point to URLs like @scheme{/posts/post1}. These are not continuation links - they are permanent, memorable, bookmarkable links to the posts, generated from the rules in @scheme{site.ss}.

It is worth noting that you can still call Delirium controller by continuation using just like you can any other Scheme procedure. For example, this code creates a link to @scheme[index] using @scheme[send/suspend/dispatch]:

@(schemeblock
  (send/suspend/dispatch
   (lambda (embed-url)
     `(html (body (a ([href ,(embed-url index)])
                     "Back to the index"))))))

@section{Define a custom 404 handler}

We can replace Dispatch's default 404 Not Found handler with our own code by passing an extra keyword argument to @scheme[serve/dispatch]:

@(schemeblock
  (serve/dispatch
   site
   #:file-not-found-responder
   (lambda (request)
     '(html (head (title "404"))
            (body (p "Oops! "
                     "We could not find what you were looking for."))))))

@section{Next steps...}

The quick start has demonstrated how to get up and running with Dispatch. However, there are many more features that we have not covered. You can find more information in the @secref{api} documentation below, including:

@itemize{
  @item{how to define your own argument types for use in URL patterns;}
  @item{how to define controllers that can only be called by continuation;}
  @item{how to create @scheme{controller wrappers} to abstract common setup tasks (e.g. user authentication and cookie handling);}
  @item{how to customise Dispatch to use other Untyped libraries such as Mirrors.plt.}}
