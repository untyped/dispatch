#lang scribble/doc

@(require scribble/eval
          scribble/manual
          (planet cce/scheme:6:0/scribble)
          (for-label scheme/base
                     "../main.ss"))

@title[#:tag "api"]{API Reference}

The entire API for Dispatch is made available by requiring a single file:

@(defmodule/this-package)

@section{Defining sites and controllers}

@defform/subs[(define-site id (rule ...) site-keyword ...)
              ([rule         (pattern controller-id)]
               [pattern      (pattern-part ...)]
               [pattern-part pattern-arg string? (-> string?)]
               [pattern-arg  arg?]
               [site-keyword (code:line #:other-controllers (id ...))
                             (code:line #:requestless? boolean?)
                             (code:line #:not-found (-> request? response?))])]{
Defines a new @italic{site} called @scheme[id] and a set of @italic{controllers} called @scheme[controller-id].

Controllers are referenced within the site via a collection of @scheme[rules]. Each controller is bound to a single identifier, but may be referenced by as many rules as desired. When a request is dispatched using @scheme[site-dispatch], the rules are evaluated in order until one of the @scheme[pattern]@schemeidfont{s} matches. The corresponding controller is called and passed the request and any @scheme[pattern-arg]@schemeidfont{uments}.

The @scheme[pattern]@schemeidfont{s} are compiled into regular expressions that are matched against the the path part of the @scheme[request-uri]. Anchor strings (@scheme{#anchor}), request arguments (@scheme{?a=b&c=d}) and trailing slashes (@scheme{/}) are ignored.

@scheme[pattern-part]@schemeidfont{s} may be one of three types:

@itemize{
  @item{@scheme[string]@schemeidfont{s} are matched verbatim;}
  @item{@scheme[thunk]@schemeidfont{s} are executed at dispatch time and their results are matched verbatim;}
  @item{@scheme[arg]@schemeidfont{s} capture patterns in the URL and convert them to Scheme values that are passed to the controller.}}

The optional @scheme[site-keyword]@schemeidfont{s} are as follows:

@scheme[#:other-controllers] specifies extra controllers that are not bound to any URL. These controllers behave like normal controller procedures except that they are incompatible with @scheme[controller-url] and @scheme[controller-link] and cannot be dispatched to using @scheme[site-dispatch].

@scheme[#:rule-not-found] specifies the behaviour of @scheme[site-dispatch] when no rule is found. The value must be a procedure that accepts the current @scheme[request] and returns a @scheme[response] (xexprs and other shortcuts are not allowed). The default behaviour is to raise @scheme[exn:dispatch], which causes the web server to skip the servlet and continue to the next dispatcher procedure.

If @scheme[#:requestless?] argument is specified and set to @scheme[#t], the defined controllers are modified so they do not take @scheme[request] arguments. This is useful when using Dispatch with @italic{Smoke}, another Untyped library.}

@defform[(site-out site)]{
@scheme[provide] form that provides @scheme[site] and its associated controllers.}

@defform/subs[(define-controller (id arg ...) controller-keyword ... expr ...)
              ([controller-keyword (code:line #:access?      boolean?)
                                   (code:line #:requestless? boolean?)
                                   (code:line #:access-proc  (arg ... -> boolean?))
                                   (code:line #:denied-proc  (controller arg ... -> any))
                                   (code:line #:wrapper-proc (controller arg ... -> any))])]{
Initialises @scheme[id], which must be a controller bound using @scheme[define-site]. Equivalent to a standard procedure definition:

@(schemeblock
  (define (id arg ...)
    expr ...))

The @scheme[arg]@schemeidfont{uments} can be normal, optional or keyword arguments as supported by the @scheme[scheme] and @scheme[scheme/base] languages. Multiple return values are also allowed. The first argument is always the @scheme[request] passed to @scheme[site-dispatch], unless the controller is defined as @scheme[#:requestless?] (see below).

Controllers can be called directly just like normal Scheme procedures. Calling a controller executes a @italic{wrapper} procedure that eventually calls the main body of the controller. The default wrapper:

@itemize{
  @item{checks the controller's access predicate (specified by the @scheme[default-access-procedure] parameter, or optionally overridden with the @scheme[#:access?] or @scheme[#:access-proc] @scheme[controller-keywords]);}
  @item{if the predicate returns @scheme[#t], the wrapper calls the main controller body;}
  @item{if the predicate returns @scheme[#f], the wrapper calls the controller's @italic{access denied} procedure (specified by the @scheme[default-access-denied] parameter, or optionally overridden with the @scheme[#:denied-proc] @scheme[controller-keyword]).}}

The @scheme[controller-keyword]@schemeidfont{s} are as follows:

@scheme[#:access?] overrides the @scheme[default-access-procedure] for this controller. The value must be a boolean expression. For example:

@(schemeblock
  (define-controller (divide-by request numerator denominator)
    #:access? (not (zero? denominator))
    (/ numerator denominator)))

@scheme[#:access-proc] is equivalent to @scheme[#:access?] but allows you to specify a complete procedure to check the access. The procedure must take the same arguments as the controller, including any request argument, and return a boolean. For example:

@(schemeblock
  (define-controller (divide-by request numerator denominator)
    #:access-proc (lambda (request num den)
                    (not (zero? den)))
    (/ numerator denominator)))

Normally, controllers should If @scheme[#:requestless?] is specified and set to @scheme[#t], the controller does

@scheme[#:denied-proc] TODO

@scheme[#:wrapper-proc] TODO}

@section[#:tag "standard-args"]{Standard URL pattern arguments}

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

@section{Dispatching an initial request}

@defproc[(dispatch [request request?] [site site?]) any]{

Dispatches @scheme[request] to the relevant controller in @scheme[site]. The rules in @scheme[site] are examined in sequence, and the request is dispatched to the controller in the first matching rule found. Default error pages are provided in case no rules match (a 404 response) or no matching @scheme[define-controller] statement is found.

If you are writing a servlet directly you should call @scheme[dispatch] directly from your @scheme[start] procedure:

@(schemeblock
  (define (start initial-request)
    (dispatch initial-request my-site)))

If you are using the @scheme[web-server/servlet-env] module you should call to @scheme[dispatch] from the procedure you pass to @scheme[serve/servlet]:

@(schemeblock
  (serve/servlet (lambda (initial-request)
                   (dispatch initial-request my-site))))}

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

@section[#:tag "custom-args"]{Custom URL pattern arguments}

In addition to the arguments described in @secref{standard-args}, you can also create your own arguments that capture/serialize arbitrary Scheme values. A pattern argument consists of four things:

@itemize{
  @item{a symbolic @italic{name}, used when printing the argument;}
  @item{a @italic{regular expression fragment}, used by @scheme[dispatch] to determine whether a URL matches the pattern;}
  @item{a @italic{decoder} procedure, used by @scheme[dispatch] to convert a captured URL fragment into a useful Scheme datum;}
  @item{an @italic{encoder} procedure, used by @scheme[controller-url] to convert a Scheme datum into a URL fragment.}}

@defproc[(make-arg [name symbol?] [pattern string?] [decoder (-> string? any)] [encoder (-> any string?)]) arg?]{

Creates a URL pattern argument. @scheme[name] is a symbolic name used in debugging output. @scheme[pattern] is a regular expression fragment written as a string in the @scheme[pregexp] language. @scheme[decoder] and @scheme[encoder] are used to convert between captured URL fragments Scheme values.}

When @scheme[dispatch] is trying to match a request against a rule, it uses a regular expression that it assembles from the parts of @scheme[url] clause. For example, consider the form:

@(schemeblock
  (url "/posts/" (integer-arg) "/" (integer-arg)))

Literal strings in the pattern are passed through @scheme[pregexp-quote] to remove the special meanings of any reserved characters. Args are converted to fragments using their pattern fields, which are wrapped in parentheses to enable regular expression capture:

@(schemeblock
  (code:comment "The pattern of an integer-arg is \"[-]?[0-9]+\":")
  (string-append "\\/posts\\/" 
                 (string-append "(" "[-]?[0-9]+" ")")
                 "\\/"
                 (string-append "(" "[-]?[0-9]+" ")")))

The whole expression is wrapped in beginning- and end-of-text anchors, and an extra fragment is added to the end of the expression to account for trailing slashes:

@(schemeblock
  (string-append "^"
                 (string-append "\\/posts\\/"
                                (string-append "(" "[-]?[0-9]+" ")")
                                "\\/"
                                (string-append "(" "[-]?[0-9]+" ")"))
                 "\\/?$"))

The request URL is matched against the final regular expression. If a match is found, the captured substrings are converted into useful values using the @scheme[decoder] procedures of the relevant arguments, and the values are passed as arguments to the controller. If no match is found, @scheme[dispatch] procedures to the next rule in the site.

Conversely, @scheme[controller-url] assembles a URL from the first pattern it finds with the correct controler and arity. It passes the controller arguments through the @scheme[encoder] fields of the relevant pattern args, and assembles a URL from the complete pattern.

As an example, here is an argument that captures co-ordinate strings like @scheme{1,2} and converts them to @scheme[cons] cells:

@(schemeblock
  (make-arg 'coord
            "[-]?[0-9]+,[-]?[0-9]+"
            (lambda (raw)
              (define x (string-index raw #\,))
              (cons (string->number (substring raw 0 x))
                    (string->number (substring raw (add1 x)))))
            (lambda (pair)
              (format "~a,~a" (car pair) (cdr pair)))))

@section{Useful predicates, accessors and mutators}

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
