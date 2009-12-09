#lang scribble/doc

@(require scribble/eval
          scribble/manual
          (planet cce/scheme:6:0/scribble)
          (for-label scheme/base
                     "../main.ss"))

@title{@bold{Dispatch}: Binding URLs to Procedures}

Dave Gurnell

@tt{dave at @link["http://www.untyped.com"]{@tt{untyped}}}

@italic{Dispatch.plt} is a web development tool for creating a two-way mapping between permanent URLs and request-handling procedures known as @italic{controllers}. Key features include:

@itemize{
  @item{simple configuration of URLs and @italic{controller} procedures;}
  @item{mechanisms for separating mutually dependent view and controller code despite the unidirectionality of PLT @scheme[require] statements;}
  @item{simple access control based on controllers and controller arguments;}
  @item{tools for creating access control aware hyperlinks between controllers;}
  @item{dynamic reconfiguration of URLs at runtime.}}

The @seclink["intro"]{first section} of this document provides a brief overview of the features of Dispatch. The @seclink["quick"]{second section} provides a working example of how to set up a simple blog from scratch. The @seclink["api"]{third section} provides a reference for the Dispatch API.

@include-section{overview.scrbl}
@include-section{quick.scrbl}
@include-section{api.scrbl}

@section{Acknowledgements}

Many thanks to the following for their contributions: Jay McCarthy, Karsten Patzwaldt and Noel Welsh.
