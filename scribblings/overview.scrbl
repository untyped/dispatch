#lang scribble/doc

@(require scribble/eval
          scribble/manual
          (planet cce/scheme:6:0/scribble)
          (for-label scheme/base
                     "../main.ss"))

@title[#:tag "intro"]{Overview}

@section{URLs to controllers}

The namesake feature of Dispatch is the ability to dispatch HTTP requests to controller procedures. Imagine you are writing a blog application where you want the following URLs to point to the most important parts of the site:

@itemize{
  @item{the URL @scheme{http://www.example.com/} should map to the procedure call @scheme[(list-posts)];}
  @item{URLs like @scheme{http://www.example.com/posts/hello-world} should map to procedure calls like @scheme[(review-post "hello-world")];}
  @item{URLs like @scheme{http://www.example.com/archive/2008/02} should map to procedure calls like @scheme[(review-archive 2008 2)].}}

Dispatch makes it simple to create this kind of configuration using code like the following:

@(schemeblock
  (define-site blog
    ([("") list-posts]
     [("/posts/" (string-arg)) review-post]
     [("/archive/" (integer-arg) "/" (integer-arg))
      review-archive]))
  
  (code:comment "request -> response")  
  (define-controller (list-posts request)
    (code:comment "..."))
  
  (code:comment "request string -> response")  
  (define-controller (review-post request slug)
    (code:comment "..."))
    
  (code:comment "request integer integer -> response")  
  (define-controller (review-archive request year month)
    (code:comment "...")))

@section{Controllers to URLs}

Dispatch helps further by providing reverse mappings to URLs from would-be calls to controllers. For example, the code:

@(schemeblock (controller-url display-archive 2008 02))

applied to @scheme[display-archive] from the example above would construct and return the value @scheme{/archive/2008/2}.

@section{Clean separation of view and controller}

The @scheme[define-site] macro binds identifiers for the site and all its controllers. @scheme[define-controller] doesn't actually bind any new identifiers - it mutates the identifiers bound by @scheme[define-site] so that they point to the relevant definitions.

This means that by placing your @scheme[define-site] expression in a central module and requiring it into all your view and controller code, you can access your controller definitions from anyehere in your entire application.

@section{Access control (new in Dispatch 3)}

Suppose we want to restrict access to older archives to paid blog members only. We can do this with Dispatch using the @scheme[#:access?] subclause of @scheme[define-controller]:

@(schemeblock
  (define-controller (review-archive request year month)
    #:access? (or (paid-subscriber? (current-user))
                  (= year (current-year)))
    (code:comment "...")))

Behind the scenes, Dispatch compiles the #:scheme[access?] expression to a separate @italic{access predicate} with the same arguments as the controller. 

The access predicate is run immediately before the main body of the controller, whever the controller is called. If the predicate returns @scheme[#f], the user is redirected to a standard ``access denied'' page.

The access predicate can also be invoked separately from the rest of the controller. Calling:

@(schemeblock (controller-access? review-archive 2009 12))

invokes the access predicate and returns its result.

@section{Hyperlink generation}

Dispatch contains a @scheme[controller-link] procedure that renders hyperlinks to controllers:

@(schemeblock
  (controller-link review-archive year month
                   #:body (format "Archive for ~a-~a" year month)
                   #:else 'hide))

In this example, if the user doesn't have access to @scheme[review-controller], the link will be hidden. There are also options to render links as plain text or @tt{<span>} tags.
