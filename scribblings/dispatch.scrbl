#lang scribble/doc

@(require scribble/eval
          scribble/manual
          (for-label scheme/base
                     "../dispatch.ss"))

@title{@bold{Dispatch}: Binding URLs to Procedures}

Dave Gurnell

@tt{dave at @link["http://www.untyped.com"]{@tt{untyped}}}

@italic{Dispatch} is a web development tool for creating a two-way mapping between permanent URLs and request-handling procedures known as @italic{controllers}. The library provides a simple means of dispatching requests to matching controllers and of reconstructing URLs from controller calls.

The @seclink["intro"]{first section} of this document provides a brief overview of the features of Dispatch. The @seclink["quick"]{second section} provides a working example of how to set up a simple blog from scratch using Dispatch. The @seclink["api"]{third section} provides a reference for the Dispatch API.

@section[#:tag "intro"]{Overview}

@subsection{URLs to controllers}

The namesake feature of Dispatch is the ability to dispatch HTTP requests to controller procedures. Imagine you are writing a blog application and you want the following URLs to point to the most important parts of the site:

@itemize{
  @item{the URL @scheme{http://www.example.com/} should map to the procedure call @scheme[(list-posts)];}
  @item{URLs like @scheme{http://www.example.com/posts/hello-world} should map to procedure calls like @scheme[(review-post "hello-world")];}
  @item{URLs like @scheme{http://www.example.com/archive/2008/02} should map to procedure calls like @scheme[(review-archive 2008 2)].}}

Dispatch makes it very easy to create this kind of configuration using code like the following:

@schemeblock[
  (define-site blog
    ([(url "") list-posts]
     [(url "/posts/" (string-arg)) review-post]
     [(url "/archive/" (integer-arg) "/" (integer-arg))
      review-archive]))
  
  (code:comment "request -> response")  
  (define-controller (list-posts request)
    ...)
  
  (code:comment "request string -> response")  
  (define-controller (review-post request slug)
    ...)
    
  (code:comment "request integer integer -> response")  
  (define-controller (review-archive year request month)
    ...)]

@subsection{Controllers to URLs}

Dispatch helps further by providing a way of recreating URLs from would-be calls to controllers. For example, the code:

@schemeblock[
  (controller-url display-archive 2008 02)]

applied to @scheme[display-archive] from the example above would construct and return the value @scheme{/archive/2008/2}.

@subsection{Clean separation of view and controller}

The @scheme[define-site] macro binds identifiers for the site and all its controllers. @scheme[define-controller] mutates the controllers defined by @scheme[define-site] so that they contain the relevant controller bindings.

This separation of interface and implementation means that there is a simple way of accessing all your controllers from anywhere in your application, without having to worry about cyclic module dependencies. Simply place the @scheme[define-site] statement in a central configuration module (conventionally named @scheme{site.ss}) and require this module from all other modules in the application to gain access to your controllers. As long as the various @scheme[define-controller] statements are executed once when the application is started, the majority of the application only needs to know about @scheme{site.ss}.

@section[#:tag "quick"]{Quick Start}

This section provides a worked example of using Dispatch to set up the blog described earlier. The example also uses Instaservlet to simplify the web server configuation. Some details are skipped over here: see the @secref["api"] for more information on the macros and procedures used.

@subsection{Create the site}

The first step is to create a @italic{site} definition using @scheme[define-site]. Create a directory called @scheme{blog} and in it create a file called @scheme{blog/site.ss}. Edit this file and type in the following:

@schememod[scheme/base

  (require (planet untyped/dispatch))
  
  (define-site blog
    ([(url "/") index]
     [(url "/posts/" (string-arg)) review-post]
     [(url "/archive/" (integer-arg) "/" (integer-arg))
      review-archive]))
      
  (provide (site-out blog))]

Now that the site has been defined we just need a servlet to create a working web application. We will simplify the creation of our servlet by using the @scheme[serve/dispatch] procedure. Create a file called @scheme{blog/run.ss}, edit it and type in the following:

@schememod[scheme/base

  (require (planet untyped/dispatch)
           "site.ss")

  (serve/dispatch site)]

@scheme[serve/dispatch] starts a web server and populates it with a single servlet that dispatches to @scheme[site] whenever it receives an HTTP request.

We should now be able to test the site. On the command line type:

@commandline{mzscheme run.ss}

and go to @scheme{http://localhost:8000/} in your web browser. You should see an error page saying something like ``@italic{Controller not defined}''. Also try @scheme{http://localhost:8000/posts/hello-world} and @scheme{http://localhost:8000/archive/2008/02}.

@scheme[serve/dispatch] provides a default 404 handler that it uses when it cannot find a matching rule. Test this by going to @scheme{http://localhost:8000/foo} in your browser.

@subsection{Define some controllers}

The @italic{Controller not defined} error pages above are appearing because there are no @scheme[define-controller] statements for our controllers. We will write a @scheme[define-controller] statement for @scheme[review-post] now. Create a directory @scheme{blog/controllers} and in it a file called @scheme{blog/controllers/posts.ss}. Edit this file and type in the following:

@schememod[scheme/base

  (require (planet untyped/dispatch)
           "../site.ss")
  
  (code:comment "request string -> html-response") 
  (define-controller (review-post request slug)
    `(html (head (title ,slug))
           (body (h1 "You are viewing " ,(format "~s" slug))
                 (p "And now for some content..."))))]

We need to make sure @scheme{posts.ss} gets executed so that this definition gets loaded into @scheme[blog]. To do this, add an extra clause to the @scheme[require] statement in @scheme{run.ss} so that it reads:

@schemeblock[
  (require (planet untyped/dispatch)
           "site.ss"
           "controllers/posts.ss")]

Now re-run the application and go to @scheme{http://localhost:8000/posts/hello-world} in your browser. You should see the web page we just created.

@subsection{Insert links from one controller to another}

Now that we are able to write controllers and dispatch to them, we need to know how to create links from one controller to another. Dispatch lets us do this without having to remember the URL structure of the site. Return to @scheme{blog/controllers/posts.ss} and add the following code for the @scheme[index] controller:

@schemeblock[
  (code:comment "request -> html-response") 
  (define-controller (index request)
    `(html (head (title "Index"))
           (body (h1 "Index")
                 (ul ,@(map index-item-html 
                            (list "post1"
                                  "post2"
                                  "post3"))))))

  (code:comment "string -> html")  
  (define (index-item-html slug)
    `(li (a ([href ,(controller-url review-post slug)])
            "View " ,(format "~s" slug))))]

In this code, the @scheme[index] controller is generating a list of posts using a helper procedure called @scheme[index-item-html]. @scheme[index-item-html] is using a procedure from Dispatch called @scheme[controller-url] to create URLs that point to @scheme[review-post]. @scheme[controller-url] takes as its arguments the controller to link to and the values of any URL pattern arguments: note that there is no @italic{request} argument.

Note that @scheme[review-post] is being provided from the @scheme[define-site] statement @scheme{site.ss}, not from the @scheme[define-controller] statement in the local module. We can easily move @scheme[index-item-html] out into a separate module of view code without creating a cyclic module dependency. For the moment, however, we just need to see the code working. Re-run the application and go to @scheme{http://localhost:8000/} in your browser.

You should see a list of three links. Inspect the HTML source of the page and notice that the links point to URLs like @scheme{/posts/post1}. These are not continuation links - they are permanent, memorable, bookmarkable links to the posts. What is more, these URLs are generated from the URL patterns in the definition of @scheme[blog] in @scheme{site.ss}: we can change these patterns in this one place and generated URLs will change accordingly throughout the site.

Note that we can still use continuations to call @scheme[review-post]. Simply wrap a normal procedure call in a @scheme[lambda] statement as normal:

@schemeblock[
  (code:comment "string -> html")  
  (define (index-item-html slug)
    `(li (a ([href ,(lambda (request) 
                      (review-post request slug))])
            "View " ,(format "~s" slug))))]

The URLs generated by this approach will expire after a finite time, but in exchange we get the full state-passing power of continuations.

@subsection{Define a custom 404 handler}

It is worth noting that we can replace Dispatch's default 404 Not Found handler with our own code by passing an extra keyword argument to @scheme[serve/dispatch]:

@schemeblock[
  (serve/dispatch
   site
   #:file-not-found-responder
   (lambda (request)
     '(html (head (title "404"))
            (body (p "Oops! We could not find what you were looking for.")))))]

Note that, unlike in Dispatch 1.x, we cannot achieve the same result using a catch-all "not found" rule at the end of the site. This is because @scheme[serve/dispatch] looks for static files such as CSS files and images @italic{after} it scans the rules in the site. Placing a 404 rule in the site would prevent th web server serving these static files.

@subsection{Next steps...}

The quick start has demonstrated how to get up and running with @italic{Dispatch}. However, Dispatch contains many more features that we have not covered. You can find more information in the @secref{api} documentation below, including:

@itemize{
  @item{how to define your own argument types for use in URL patterns;}
  @item{how to define controllers that can only be called by continuation;}
  @item{how to abstract common setup tasks (for example user identification, authentication, exception handling and cookie handling) into @italic{request pipelines}.}}

@section[#:tag "api"]{API Reference}

The API for Dispatch is made available by requiring a single file, @scheme{dispatch.ss}:

@defmodule[(planet untyped/dispatch)]

The following sections document the forms and procedures provided.

@subsection{Defining sites and controllers}

@defform/subs[(define-site id (rule ...) site-option ...)
              ([rule        (condition controller-id)]
               [site-option (code:line #:other-controllers (controller-id ...))
                            (code:line #:rule-not-found (request -> response))]
               [condition   (url url-part ...)]
               [url-part    string arg])]{
Creates a new @italic{site} and a set of @italic{controllers} and binds them to @scheme[id] and each unique @scheme[controller-id].

Controllers are referenced within the site via a collection of @scheme[rules]. Each controller is bound to a single identifier, but may be referenced by as many rules as desired. When a request is dispatched to the site using @scheme[dispatch], the rules are evaluated in the order specified until a match is found. The corresponding controller is called and passed the request and any arguments from the rule's condition(s).

Currently only one type of condition is supported: the @scheme[url] form creates a regular expression pattern that is matched against the the path part of the request URL. String arguments to @scheme[url] are matched verbatim; @scheme[arg] arguments capture patterns in the URL and convert them to Scheme values that are passed to the controller. Anchor strings (@scheme{#anchor}), request arguments (@scheme{?a=b&c=d}) and trailing slashes (@scheme{/}) are ignored when matching.

The optional @scheme[#:other-controllers] argument can be used to specify controllers that are not bound to any URL. These controllers may be called like normal procedures (including by continuation) but cannot be used with @scheme[controller-url].}

The optional @scheme[#:rule-not-found] argument can be used to specify a procedure to call when no matching controller is found. This is useful if you want to override the default 404 page without defining a special controller.

@defform[(site-out site)]{
Provide form that provides @scheme[site] and its associated controllers.}

@defform*/subs[((define-controller (id arg ...) expr ...)
                (define-controller id pipeline procedure))
               ([pipeline (listof stage)])]{
               
Initialises @scheme[id], which must be a controller bound using @scheme[define-site]. The first form is the equivalent of a standard PLT procedure definition:

@schemeblock[
  (define (id arg ...)
    expr ...)]

allowing all the same features including keyword arguments, optional arguments and multiple return values. The second form allows you to specify a @italic{request pipeline} to use with the controller. Pipelines are a useful abstraction for common tasks to perform when the controller is called and/or returns. Pipelines are part of the unlib.plt package, and are beyond the scope of this document. See the documentation for unlib.plt for more information.

Controllers can be called directly just like normal Scheme procedures. If a controller has no pipeline, calling it is equivalent to calling its body procedure. For example, given an appropriate site definition and the code:

@schemeblock[
  (define-controller (my-controller request a b c)
    (code:comment "... "))]
    
calling @scheme[(my-controller request 1 2 3)] is equivalent to calling:

@schemeblock[
  ((lambda (request a b c)
     (code:comment "... "))
   request 1 2 3)]

If a controller is defined with a pipeline:

@schemeblock[
  (define-controller my-controller
    my-pipeline
    (lambda (request a b c)
      (code:comment "... ")))]

calling @scheme[(my-controller request 1 2 3)] is equivalent to calling:

@schemeblock[
  (call-with-pipeline my-pipeline
                      (lambda (request a b c)
                        (code:comment "... "))
                      request 1 2 3)]}

@subsection[#:tag "standard-args"]{Standard URL pattern arguments}

Dispatch provides several built-in types of URL pattern arguments:

@defproc[(integer-arg) arg?]{
Creates an argument that captures a section of the URL, converts it to an integer and passes it as an argument to the controller. Equivalent to the regular expression @scheme[#rx"[-]?[0-9]+"].}

@defproc[(real-arg) arg?]{
Similar to @scheme[integer-arg] except that it captures real numbers. Equivalent to the regular expression @scheme[#rx"[-]?[0-9]+|[-]?[0-9]*.[0-9]+"].}

@defproc[(string-arg) arg?]{
Creates an argument that matches one or more non-slash characters and passes them as an argument to the controller. Equivalent to the regular expression @scheme[#rx"[^/]+"].}

@defproc[(symbol-arg) arg?]{
Similar to @scheme[string-arg] except that the captured pattern is converted to a symbol before it is passed to the controller.}

@defproc[(rest-arg) arg?]{
Similar to @scheme[string-arg] except that it captures @italic{any} characters including slashes. Equivalent to the regular expression @scheme[#rx".*"]. Note that trailing slashes in the URL never get matched.}

You can also make your own types of pattern argument in addition to the above. See @secref{custom-args} for more information.

@subsection{Dispatching an initial request}

@defproc[(dispatch [request request?] [site site?]) any]{

Dispatches @scheme[request] to the relevant controller in @scheme[site]. The rules in @scheme[site] are examined in sequence, and the request is dispatched to the controller in the first matching rule found. Default error pages are provided in case no rules match (a 404 response) or no matching @scheme[define-controller] statement is found.

If you are writing a servlet directly you should call @scheme[dispatch] directly from your @scheme[start] procedure:

@schemeblock[
  (define (start initial-request)
    (dispatch initial-request my-site))]

If you are using the @scheme[web-server/servlet-env] module you should call to @scheme[dispatch] from the procedure you pass to @scheme[serve/servlet]:

@schemeblock[
  (serve/servlet (lambda (initial-request)
                   (dispatch initial-request my-site)))]}

@defproc[(serve/servlet
          [site+start                  (or/c site? (-> request? response/c))]
          [#:command-line?             command-line?     boolean?          #f]
          [#:launch-browser?           launch-browser?   boolean?          (not command-line?)]
          [#:quit?                     quit?             boolean?          (not command-line?)]
          [#:banner?                   banner?           boolean?          (not command-line?)]
          [#:listen-ip                 listen-ip         (or/c string? #f) "127.0.0.1"]
          [#:port                      port              number?           8000]
          [#:ssl?                      ssl?              boolean?          #f]
          [#:servlet-path              servlet-path      string?           "/"]
          [#:servlet-regexp            servlet-regexp    regexp?           #rx""]
          [#:stateless?                stateless?        boolean?          #f]
          [#:stuffer                   stuffer           (stuffer/c serializable? bytes?)
                                                         default-stuffer]
          [#:manager                   manager           manager?
                                                         (make-threshold-LRU-manager #f (* 1024 1024 64))]
          [#:servlet-namespace         servlet-namespace (listof module-path?)
                                                         empty]
          [#:server-root-path          server-root-path  path-string?
                                                         default-server-root-path]
          [#:extra-files-paths         extra-files-paths (listof path-string?)
                                                         (list (build-path server-root-path "htdocs"))]
          [#:servlets-root             servlets-root     path-string? (build-path server-root-path "htdocs")]
          [#:servlet-current-directory servlet-current-directory
                                       path-string?
                                       servlets-root]
          [#:file-not-found-responder  file-not-found-responder
                                       (-> request? response/c)
                                       dispatch-not-found-responder]
          [#:mime-types-path           mime-types-path   path-string?           ...]
          [#:log-file                  log-file          (or/c path-string? #f) #f]
          [#:log-format                log-format        log-format/c           'apache-default])
         void]{
A wrapper for the Web Server's @scheme[serve/servlet]. Quickly configures default server instance. Most arguments are the same as those for @scheme[serve/servlet], with three notable exceptions:

The @scheme[start] argument from @scheme[serve/servlet] has been replaced with @scheme[site+start], which can be a procedure from a request to a response or a Dispatch site. If this argument is a site, the web server dispatches incoming requests straight there. If the argument is a procedure, it should call @scheme[dispatch] with an appropriate request and site.

The default values of @scheme[servlet-path] and @scheme[servlet-regexp] have been changed to @scheme[""] and @scheme[#rx""] respectively. This causes all requests to be sent to @scheme[site+servlet]. If Dispatch cannot find a matching rule it raises @scheme[exn:dispatch], passing control back to @scheme[serve/servlet].

The default value of @scheme[file-not-found-responder] has been replaced with Dispatch's @italic{controller not found} message.}

@subsection[#:tag "custom-args"]{Custom URL pattern arguments}

In addition to the arguments described in @secref{standard-args}, you can also create your own arguments that capture/serialize arbitrary Scheme values. A pattern argument consists of four things:

@itemize{
  @item{a symbolic @italic{name}, used when printing the argument;}
  @item{a @italic{regular expression fragment}, used by @scheme[dispatch] to determine whether a URL matches the pattern;}
  @item{a @italic{decoder} procedure, used by @scheme[dispatch] to convert a captured URL fragment into a useful Scheme datum;}
  @item{an @italic{encoder} procedure, used by @scheme[controller-url] to convert a Scheme datum into a URL fragment.}}

@defproc[(make-arg [name symbol?] [pattern string?] [decoder (-> string? any)] [encoder (-> any string?)]) arg?]{

Creates a URL pattern argument. @scheme[name] is a symbolic name used in debugging output. @scheme[pattern] is a regular expression fragment written as a string in the @scheme[pregexp] language. @scheme[decoder] and @scheme[encoder] are used to convert between captured URL fragments Scheme values.}

When @scheme[dispatch] is trying to match a request against a rule, it uses a regular expression that it assembles from the parts of @scheme[url] clause. For example, consider the form:

@schemeblock[
  (url "/posts/" (integer-arg) "/" (integer-arg))]

Literal strings in the pattern are passed through @scheme[pregexp-quote] to remove the special meanings of any reserved characters. Args are converted to fragments using their pattern fields, which are wrapped in parentheses to enable regular expression capture:

@schemeblock[
  (code:comment "The pattern of an integer-arg is \"[-]?[0-9]+\":")
  (string-append "\\/posts\\/" 
                 (string-append "(" "[-]?[0-9]+" ")")
                 "\\/"
                 (string-append "(" "[-]?[0-9]+" ")"))]

The whole expression is wrapped in beginning- and end-of-text anchors, and an extra fragment is added to the end of the expression to account for trailing slashes:

@schemeblock[
  (string-append "^"
                 (string-append "\\/posts\\/"
                                (string-append "(" "[-]?[0-9]+" ")")
                                "\\/"
                                (string-append "(" "[-]?[0-9]+" ")"))
                 "\\/?$")]

The request URL is matched against the final regular expression. If a match is found, the captured substrings are converted into useful values using the @scheme[decoder] procedures of the relevant arguments, and the values are passed as arguments to the controller. If no match is found, @scheme[dispatch] procedures to the next rule in the site.

Conversely, @scheme[controller-url] assembles a URL from the first pattern it finds with the correct controler and arity. It passes the controller arguments through the @scheme[encoder] fields of the relevant pattern args, and assembles a URL from the complete pattern.

As an example, here is an argument that captures co-ordinate strings like @scheme{1,2} and converts them to @scheme[cons] cells:

@schemeblock[
  (make-arg 'coord
            "[-]?[0-9]+,[-]?[0-9]+"
            (lambda (raw)
              (define x (string-index raw #\,))
              (cons (string->number (substring raw 0 x))
                    (string->number (substring raw (add1 x)))))
            (lambda (pair)
              (format "~a,~a" (car pair) (cdr pair))))]

@subsection{Useful predicates, accessors and mutators}

@defproc[(site? [site any]) boolean?]{
Returns @scheme[#t] if the argument is a site, @scheme[#f] otherwise.}

@defproc[(site-id [site site?]) symbol?]{
Returns a symbolic version of the identifier to which @scheme[site] is bound.}

@defproc[(site-controllers [site site?]) (listof controller?)]{
Returns a listof the controllers that are part of @scheme[site].}

@defproc[(controller? [site any]) boolean?]{
Returns @scheme[#t] if the argument is a controller, @scheme[#f] otherwise.}

@defproc[(controller-id [controller controller?]) symbol?]{
Returns a symbolic version of the identifier to which @scheme[controller] is bound.}

@defproc[(controller-site [controller controller?]) site?]{
Returns the site associated with @scheme[controller].}

@defproc[(controller-pipeline [controller controller?]) (listof (request? -> response/c))]{
Returns @scheme[controller]'s pipeline, or @scheme[null] if @scheme[controller] has no pipeline. Raises @scheme[exn:fail:contract] if @scheme[controller] has not been initialised with @scheme[define-controller].}

@defproc[(controller-body [controller controller?]) procedure?]{
Returns @scheme[controller]'s body procedure. Raises @scheme[exn:fail:contract] if @scheme[controller] has not been initialised with @scheme[define-controller].}

@defproc[(controller-url [controller controller?] [arg any] ...) string?]{
Returns a host-local URL that, when visited, would result in @scheme[controller] getting called with the specified arguments. Raises @scheme[exn:fail:dispatching] if there is no rule of matching arity associated with @scheme[controller].}

@defproc[(arg? [arg any]) boolean?]{
Returns @scheme[#t] if the argument is a URL pattern argument, @scheme[#f] otherwise.}

@defproc[(arg-id [arg arg?]) symbol?]{
Returns the name of @scheme[arg], for use in debugging output.}

@defproc[(set-arg-id! [arg arg?] [id symbol?]) void?]{
Sets the name of @scheme[arg] to @scheme[id].}

@defproc[(arg-pattern [arg arg?]) string?]{
Returns the regular expression fragment of @scheme[arg].}

@defproc[(set-arg-pattern! [arg arg?] [pattern string?]) void?]{
Sets the regular expression fragment of @scheme[arg] to @scheme[pattern], which should be written in the @scheme[pregexp] language and should not contain capturing parentheses or beginning- or end-of-text markers (@scheme{^} or @scheme{$}).}

@defproc[(arg-decoder [arg arg?]) (-> string? any)]{
Returns the decoder procedure associated with @scheme[arg].}

@defproc[(set-arg-decoder! [arg arg?] [proc (-> string? any)]) void?]{
Sets the decoder procedure of @scheme[arg] to @scheme[proc].}

@defproc[(arg-encoder [arg arg?]) (-> any string?)]{
Returns the encoder procedure associated with @scheme[arg].}

@defproc[(set-arg-encoder! [arg arg?] [proc (-> any string?)]) void?]{
Sets the encoder procedure of @scheme[arg] to @scheme[proc].}

@section{Acknowledgements}

Many thanks to the following for their contributions: Jay McCarthy, Karsten Patzwaldt and Noel Welsh.
