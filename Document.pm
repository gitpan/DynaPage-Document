### //////////////////////////////////////////////////////////////////////////
#
#	TOP
#

=head1 NAME

DynaPage::Document - DynaPage Document container

 #------------------------------------------------------
 # (C) Daniel Peder & Infoset s.r.o., all rights reserved
 # http://www.infoset.com, Daniel.Peder@infoset.com
 #------------------------------------------------------

=cut

###													###
###	size of <TAB> in this document is 4 characters	###
###													###

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: intro
#

=head1 SYNOPSIS

step1 - B<document> ( create file mydoc.document )

  ---[content of mydoc-document.info]---

  !include.template =- mydoc-template.htmt
  my-title =- This is single line
  my-head =- Hello World
  my-para ==~
   This is block
   multiline content
   blah blah
   blah blah
  ~== my-para 

  ---[content of mydoc-document.info]---

step2 - B<template> ( create file mydoc.template )

  ---[content of mydoc-template.htmt]---

  <html>
  <title>[~my-title~]</title>
  <h1>[~my-head~]</h1>
  <p>[~my-para~]</p>
  </html>

  ---[content of mydoc-template.htmt]---

step3 - B<open>

  use DynaPage::Document;
  use DynaPage::Document::ext::include;
  my $doc = DynaPage::Document->new(
    {
      RootDir=>'.',
      Document=>'mydoc-document.info',
    }
  );

step4 - B<render>
 
 print $doc->Render();

  ---[dump of printed result]---
  <html>
  <title>This is single line</title>
  <h1>Hello World</h1>
  <p>   This is block
   multiline content
   blah blah
   blah blah</p>
  </html>
  ---[dump of printed result]---


See also 

B<Working copy of this SYNOPSIS :>

 .../DynaPage/Document/EXAMPLES/SYNOPSIS
 
B<Other EXAMPLES :>

 .../DynaPage/Document/EXAMPLES/
 
B<How to make it with Apache2/mod_perl2 :>

 SYNOPSIS of DynaPage::Apache2

B<Powerfull extensions to increase website building productivity>
 
 METHODS of DynaPage::Document::ext::include
  
=head1 DESCRIPTION

=cut



### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: package
#

    package DynaPage::Document;


### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: version
#

	use vars qw( $VERSION $VERSION_LABEL $REVISION $REVISION_DATETIME $REVISION_LABEL $PROG_LABEL );

	$VERSION           = '0.90';
	
	$REVISION          = (qw$Revision: 1.10 $)[1];
	$REVISION_DATETIME = join(' ',(qw$Date: 2005/01/14 12:23:49 $)[1,2]);
	$REVISION_LABEL    = '$Id: Document.pm,v 1.10 2005/01/14 12:23:49 root Exp root $';
	$VERSION_LABEL     = "$VERSION (rev. $REVISION $REVISION_DATETIME)";
	$PROG_LABEL        = __PACKAGE__." - ver. $VERSION_LABEL";

=pod

 $Revision: 1.10 $
 $Date: 2005/01/14 12:23:49 $

=cut


### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: debug
#

	# use vars qw( $DEBUG ); $DEBUG=0;
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: constants
#

	# use constant	name		=> 'value';
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: modules use
#

	require 5.005_62;

	use strict                  ;
	use warnings                ;
	
	use	DynaPage::Sourcer		;
	use	DynaPage::Template		;
	use	IO::File::String		;
	use	File::Spec				;
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: class properties
#

#	our	$config	= 
#	{
#	};
	

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: methods
#

=head1 METHODS

=over 4

=cut



### ##########################################################################

=item	new ( $options ) : blessed

example:

$options = {
	
	RootDir  => '/my/RootDir/'
	Document => '//my/RootDir/BaseDir/Document.info',
	Template => '//my/work/dir/include/Template.htmt',
	DocumentDir  => '/my/RootDir/BaseDir/'

	Data => $data_for_sourcer,
	
	HooksEnable => 1,
}

B<RootDir> must be allways specified as absolute path.

Double slashed path for B<Document> and B<Template> forces absolute path within 
filesystem.

B<BaseDir> is absolute path to directory where is the B<Document> located.

Path specifications within the B<Document> :

 - without leading slash - relative to BaseDir
 - with single leading slash - relative to RootDir
 - with double leading slash - absolute to filesystem
 
B< HooksEnable > is by default set to true. Set it to FALSE to disable hooks.

=cut

### --------------------------------------------------------------------------
sub		new
### --------------------------------------------------------------------------
{
	my( $proto, $options ) = @_;
	
	my	$self  = {};
		bless( $self, (ref( $proto ) || $proto ));
		
		# OPTIONS
		
		$options->{HooksEnable} = 1 unless exists $options->{HooksEnable};
		
		$self->{OPTIONS} = $options;
		
		$self->RootDir( $options->{RootDir} ) or die "RootDir option must be specified.";
	
		$self->{Sourcer}	= 
	my	$Sourcer			= DynaPage::Sourcer->new();

		# set Default values
		$Sourcer->Add( 'DynaPage.PROG_LABEL'=> $PROG_LABEL ) ;

		# set Document		
		if( $options->{DocumentDir} )
		{
			$self->DocumentDir( $options->{DocumentDir} )
		}
		if( my $Document = $options->{Document} )
		{
			my($volume,$directories,$file) = File::Spec->splitpath( $Document );
			unless( $self->DocumentDir() )
			{
				$self->DocumentDir( $directories );
			}
            $self->{DocumentFilename} = $file;
            $Sourcer->Set( 'D_DocumentFilename' => $file ); # TODO: move it into prefixers

			if( my $docdata = $self->Read( $Document ) ) {
				$Sourcer->Parse( $docdata );
	       		#$self->HandleIncludes();
	       		$self->HandleExtensions();
	       		$Sourcer->ClearStats();
			}

#			$Sourcer->Add( '!include.data'=> $options->{Document} ) ;
#			$self->HandleIncludes();
#			$Sourcer->ClearStats();
			
		}
		unless( $self->DocumentDir() )
		{
			$self->DocumentDir( $self->RootDir() );
		}

		# set Template
		if( $options->{Template} )
		{
			$Sourcer->Add( '!include.template'=> $options->{Template} );
       		#$self->HandleIncludes();
       		$self->HandleExtensions();
			$Sourcer->ClearStats();
		}

		# handle other 'Data' content
		$Sourcer->Parse( $options->{Data} ) if $options->{Data};
   		#$self->HandleIncludes();
   		$self->HandleExtensions();
		
		# call hook
		$self->CallHook( 'Init' );
	
	$self
}


### ##########################################################################

=item	Render ( ) : string

Render final document. Just shortcut of $self->Template->Feed() .

=cut

### --------------------------------------------------------------------------
sub		Render
### --------------------------------------------------------------------------
{
	my( $self ) = @_;
    
		$self->Template->Feed();
}


### ##########################################################################

=item	SetSignal ( $name, $message ) : $string

Set internal document signal to $message value.

Set $self->{SIGNAL_STATUS} to true, increasing it by 1.

=cut

### --------------------------------------------------------------------------
sub		SetSignal
### --------------------------------------------------------------------------
{
	my( $self, $name, $message ) = @_;
    $self->{SIGNAL}{$name} = $message;
    $self->{SIGNAL_STATUS}++;
}


### ##########################################################################

=item	GetSignal ( [$name [, $clear]] ) : bool | string

Without B< $name > specified, return $self->{SIGNAL_STATUS}.

Get value of $message previously set signal $name.

With B< $clear > set to any TRUE value, the message will be cleared.

Allways clear the $self->{SIGNAL_STATUS}.

Returns undef unless signal of given B< $name > doesn't exists, this is the 
exception, when the $self->{SIGNAL_STATUS} is not cleared.

=cut

### --------------------------------------------------------------------------
sub		GetSignal
### --------------------------------------------------------------------------
{
	my( $self, $name, $clear ) = @_;
	
	if( $name && !exists( $self->{SIGNAL}{$name} )) {
        return undef
    }
	my $signal_status = delete $self->{SIGNAL_STATUS};
    return $signal_status unless $name;
    
	my $message = $self->{SIGNAL}{$name};
	delete $self->{SIGNAL}{$name} if( $clear );

	return $message
}


### ##########################################################################

=item	CallHook ( $name ) : $string

Call included document hook / if any.

=cut

### --------------------------------------------------------------------------
sub		CallHook
### --------------------------------------------------------------------------
{
	my(	$self, $hook_name, $call_params ) = @_;
	
	return 0 unless $self->{OPTIONS}{HooksEnable};
	
	return undef unless
	my	$hook = $self->{HOOK}{$hook_name};

	my	$result	= eval
		{	
			&$hook( $self, $hook_name, $call_params )
		};
		if( $@ )
		{
			warn "ERR[CallHook.$hook_name]: $@";
			$self->{HOOK_ERR}++;
			$self->{HOOK_ERRMSG}{$hook_name} = $@;
			return undef, $@;
		}
	
	return $result
}

### ##########################################################################

=item	Template ( $template_body ) : blessed Template

Get blessed Template object unless B< $template_body > specified.
Otherwise create new template object using B< template_body >.

=cut

### --------------------------------------------------------------------------
sub		Template
### --------------------------------------------------------------------------
{
	my( $self, $template_body ) = @_;

	unless( $template_body or $self->{TEMPLATE} )
	{
		# create automatic template dumping all values
		$template_body = "Automatic Template Content Dump";
		for my $name ( $self->Sourcer->Names )
		{
			next if $name =~ /^!/;
			$template_body .= qq{\n\n---\n$name:\n[~$name~]\n};
		}
		$self->Sourcer->Add( '!content-type' => 'text/plain' );
	}

    if( $template_body )
    {
		$self->{TEMPLATE} = DynaPage::Template->new( $template_body, $self->Sourcer );
	}

	$self->{TEMPLATE}
}


### ##########################################################################

=item	Sourcer ( ) : blessed Sourcer

Sourcer object.

=cut

### --------------------------------------------------------------------------
sub		Sourcer
### --------------------------------------------------------------------------
{
	my( $self ) = @_;
	
	$self->{Sourcer}    
}


### ##########################################################################

=item	Get ( @args ) : SOURCER

B<SOURCER:> see DynaPage::Sourcer for details.
This is only shortcut interface to SOURCER methods.
    
    $self->Sourcer->Get(@args)

=cut

### --------------------------------------------------------------------------
sub		Get
### --------------------------------------------------------------------------
{
	my( $self, @args ) = @_;
	return $self->Sourcer->Get(@args);
    
}

### ##########################################################################

=item	Set ( @args ) : SOURCER

B<SOURCER:> see DynaPage::Sourcer for details.
This is only shortcut interface to SOURCER methods.

    $self->Sourcer->Set(@args)

=cut

### --------------------------------------------------------------------------
sub		Set
### --------------------------------------------------------------------------
{
	my( $self, @args ) = @_;
	return $self->Sourcer->Set(@args);
    
}

### ##########################################################################

=item	Add ( @args ) : SOURCER

B<SOURCER:> see DynaPage::Sourcer for details.
This is only shortcut interface to SOURCER methods.

    $self->Sourcer->Add(@args)

=cut

### --------------------------------------------------------------------------
sub		Add
### --------------------------------------------------------------------------
{
	my( $self, @args ) = @_;
	return $self->Sourcer->Add(@args);
    
}

### ##########################################################################

=item	HandleIncludes ( ) : bool

Handle recently parsed include references:

B<!include.data> ... subdocument ... example: /myinc/subdoc.idoc

B<!include.template> ... master template ... example: /mytmplt/templt1.htmt

B<!include.parameters> ... B<PGCE> - POST, GET, COOKIES, ENV values imported into 
names with prefixes P_, G_, C_, E_, or without prefixes if specified as 
lowercase B<pgce>.

example: PGe ... will import POST and GET parameters with prefixes, ENV values 
without prefixes, COOKIES not imported.

Specifiyng 'A' or 'a' is shortcut for 'PGCE' resp. 'pgce'.

B<!include.module> ... use Any::Perl::Module::You::Wish ... multiple modules could 
be specified, each one by new single line. 

B<!include.handlers> ... will be obsoleted by include.hooks (which is better description of 
its purpose)

B<!include.hooks> ... perl script fragmets called by document parent (currently 
DynaDoc::Apache).

There are currently two hooks used by DynaPage::Apache :

 - Init            ... after Apache created DynaPage::Document object
 - DocumentFinal   ... before Apache sends the content out.

example (fragment of document containing hooks definition):

  !include.hooks ==~
  
    Init => sub {
        my( $self, $hook_name, $hashref_parameters ) = @_;
        $self->Set( my_token_name => 'Hello World');
        # my_token_name will be later inserted 
        # into Template token mark [~my_token_name~] 
        return 1;
    }
  
  ~== !include.hooks

=cut

### --------------------------------------------------------------------------
sub		HandleIncludes
### --------------------------------------------------------------------------
{
	my( $self ) = @_;
	
	while( my @newValues = $self->Sourcer->NewValues() )
	{
		my	@jobs;

		for my $command ( grep {/^!include\./} @newValues )
		{
			next unless $command =~ /^!include\.(data|template|parameters|module|hooks|handlers|field)(?:\.([\w\-\.]+))?$/;
			my	$type	= $1;
			my  $type_ext = $2;
			my	$count	= $self->Sourcer->NewValues( $command );
			for my $i ( -$count..-1 )
			{
				my	$param	= $self->Sourcer->Get( $command, $i );
				push @jobs, [ $type, $type_ext, $param ];
			}
		}

		$self->Sourcer->ClearStats();

		for my $job ( @jobs )
		{
			my( $type, $type_ext, $param ) = @$job;

			if(		$type eq 'template' )
			{
				my	$data	= $self->Read( $param );
					$self->Template( $data ) if $data;
			}
			elsif(	$type eq 'data' )
			{
				my	$data	= $self->Read( $param );
					$self->Sourcer->Parse( $data ) if $data;
			}
			elsif(	$type eq 'field' )
			{
				my	$data	= $self->Read( $param );
				if( $data ) {
    				my  $field  = $type_ext;
    				unless( $field ) {
                        $field = $param;
                        $field =~ s{.*/([^/]+)$}{$1}s; # drop dir prefix
                        $field =~ s{[^\w\-\.]+}{_}gos; # convert invalid chars
                    }
    				$self->Sourcer->Set( $field => $data );
				}
			}
			elsif(	
                ($type eq 'hooks' or $type eq 'handlers') 
                and $self->{OPTIONS}{HooksEnable} 
            )
			{
				my $hooks = eval( '{' .$param . '}' );
				if( $hooks && ref($hooks) eq 'HASH' )
				{
					for my $key ( keys %$hooks )
					{
						my $hook = $hooks->{$key};
						unless( ref($hook) eq 'CODE' )
						{
							warn "ERR[include.$type]: '$key' isn't CODE reference";
						}
						
						$self->{HOOK}{$key} = $hook;
					}
				}
				elsif( $@ )
				{
					warn "ERR[include.$type]: $@";
				}
				else
				{
					warn "ERR[include.$type]: missing correct hook definitions";
				}
			}
			elsif(	$type eq 'module' )
			{
				my @modules = grep {$_} split( '[\r\n]+', $param );
				# push @{ $self->{MODULE} }, @modules;
				for my $module ( @modules )
				{
					eval ( 'use '.$module.' ;' );
					if($@)
					{
						$self->{MODULE}{$module} = '0_ERR:'.$@;
						warn "ERR[include.$type $module]: $@";
					}
					else
					{
						$self->{MODULE}{$module} = '1_OK';
					}
				}
			}
			elsif(	$type eq 'parameters' and $ENV{MOD_PERL} )
			{

			     my $cgi = CGI->new();
			     
			     $param  =~ s/.*?a.*/pgceh/os unless
			     $param  =~ s/.*?A.*/PGCEH/os;
			     while( $param =~ m{([PGCEH])}icgos )
			     {
                    my  $param_key = $1;
                    my  $prefix = (uc($param_key) eq $param_key) ? $param_key.'_' : '';
                        $param_key = uc($param_key);
                        
                    if(     $param_key eq 'P' and $cgi->request_method() eq 'POST' ) { # POST
                        my @names = $cgi->param();
                        if(@names){
                        $self->Sourcer->Add( $prefix.'_NAMES' => join(',',@names) );
                        for(my $i=0; $i<=$#names; $i++ )
                        {
                            my  $parn = $names[$i];
                            my  $name = $prefix.$parn;
                            my  @vals = $cgi->param( $parn );
                            for my $val (@vals) {
                                $self->Sourcer->Add( $name => $val );
                            }
                        }
                        }
                    } 
                    elsif(  $param_key eq 'G' ) { # GET
                        my @names = $cgi->url_param();
                        if(@names){
                        $self->Sourcer->Add( $prefix.'_NAMES' => join(',',@names) );
                        for(my $i=0; $i<=$#names; $i++ )
                        {
                            my  $parn = $names[$i];
                            my  $name = $prefix.$parn;
                            my  @vals = $cgi->url_param( $parn );
                            for my $val (@vals) {
                                $self->Sourcer->Add( $name => $val );
                            }
                        }
                        }
                    } 
                    elsif(  $param_key eq 'C' ) { # COOKIE
                        my %cookies = CGI::Cookie->fetch();
                        for my $key ( keys %cookies )
                        {
                            my $name = $prefix.$key;
                            $self->Sourcer->Add( $name => $cookies{$key}->value() );
                        }
                    } 
                    elsif(  $param_key eq 'E' ) { # ENVIRONMENT
                        for my $key ( keys %ENV )
                        {
                            my $name = $prefix.$key;
                            $self->Sourcer->Add( $name => $ENV{$key} );
                        }
                    } 
                 }
			}
		}
        # for
	}
    # while
}


### ##########################################################################

=item	HandleExtensions ( ) : bool

Handle  extensions.
Their corresponding handlers must be 
one of following three sub references:
(only the first one found is called, lookup is in following order)

 1: DynaPage::Document::ext::B<part1>::B<Part2>::PLUG()
 2: DynaPage::Document::ext::B<part1>::B<Part2()>::PLUG
 3: DynaPage::Document::ext::B<part1>::PLUG()
 
EXAMPLE:

I<source:>

 ...
 !include.data =- /mydir/myfile.data
 ...
 
I<call:>

 DynaPage::Document::ext::include::data( 
    $Doc, [ '!include.data','/mydir/myfile.data' ] 
 )
 
I<arguments:>

B<$Doc> is current document object

B<['...','...']> is arrayref with B<field_name> and B<field_value> 
obtained during source parsing.

=cut

### --------------------------------------------------------------------------
sub		HandleExtensions
### --------------------------------------------------------------------------
{
	my( $self  ) = @_;
    
	while( my @newValues = $self->Sourcer->NewValues() )
	{
		my	@jobs;

        # register new values before processing them
        value_loop:
		for my $command ( grep {/^!/} @newValues )
		{
		      #printf STDERR "command '%s'\n", $command;
		    my @command_keys = ( $command =~ /^!(\w+)(?:\.(\w+))?/ );
		      #printf STDERR "command keys '%s'\n", join(',',@command_keys);
		    next unless @command_keys;
		    #next if $command_keys[0] eq 'include';
		    my $sub_name;
		    select_sub_name: {
		      if( $command_keys[1] ) {
		      $sub_name = "DynaPage::Document::ext::$command_keys[0]::$command_keys[1]::PLUG";
		      last select_sub_name if  defined( &$sub_name );
		      }
		      
		      if( $command_keys[1] ) {
		      $sub_name = "DynaPage::Document::ext::$command_keys[0]::$command_keys[1]";
		      last select_sub_name if defined( &$sub_name );
		      }
		      
		      $sub_name = "DynaPage::Document::ext::$command_keys[0]::PLUG";
		      last select_sub_name if defined( &$sub_name );
		      
	            #printf STDERR "drop command '%s' keys '%s'\n", $command, join(',',@command_keys);
		      next value_loop;
            };
			my	$count	= $self->Sourcer->NewValues( $command );
			for my $param_index ( -$count..-1 )
			{
				my	$param = $self->Sourcer->Get( $command, $param_index );
				push @jobs, [ $sub_name, $command, $param ];
			}
		}#endfor

		$self->Sourcer->ClearStats();

		for my $job ( @jobs )
		{
			my $sub_name = shift @$job;
			  #printf STDERR "job %s('%s')\n", $sub_name, join(',',@$job);
			eval( $sub_name.'( $self, $job )' );
			warn "HandleExtensions job [$sub_name], ERR: '$@'" if $@;
			
		}#endfor
    }#endwhile
}

### ##########################################################################

=item	Read ( $filename ) : string

Read the whole file, relative to RootDir.

=cut

### --------------------------------------------------------------------------
sub		Read
### --------------------------------------------------------------------------
{
	my( $self, $filename ) = @_;
    
		$filename	= $self->GetAbsFilename( "$filename" );

		unless( -r $filename )
		{
			push @{ $self->{ERROR} }, "Read: can't read file '$filename'";
			return undef;
		}

	$self->{FILE}{$filename}++;
	
	IO::File::String->new( "< $filename" )->load;
}


### ##########################################################################

=item	Serialize ( $filename, $fields ) : string | bool-success

Serialize document's fields.

=cut

### --------------------------------------------------------------------------
sub		Serialize
### --------------------------------------------------------------------------
{
	my( $self, $filename, @fields ) = @_;
	
	if( $filename ) {
        $filename = $self->GetAbsFilename( $filename )
    }

    unless(@fields){
        @fields=$self->Sourcer->Names();
    }
    
    my $serial = '';
    
    for my $field ( @fields )
    {
        for my $val ( $self->Get( $field )) {
            my $multiline = ( $val =~ /[\r\n]/ ) ? 1 : 0;
            if( $multiline ) {
                $serial .= sprintf "%s ==~\n%s\n~== %s\n", $field, $val, $field;
            }
            else {
                $serial .= sprintf "%s =~%s\n", $field, $val;
            }
        }
    }
    if($filename){
        return IO::File::String->new("> $filename")->save($serial);
    }
    else {
        return $serial;
    }
    
}

### ##########################################################################

=item	GetAbsFilename ( $filename )

Get absolute filename. Filenames without leading slash are
relative to B<DocumentDir> directory, of the document itself. Single leading
slash '/' is for B<RootDir> and double leading slash '//' is for absolute path
within filesystem.

=cut

### --------------------------------------------------------------------------
sub		GetAbsFilename
### --------------------------------------------------------------------------
{
	my( $self, $filename )=@_;
	
	my	$abs_filename;
	if(		$filename =~ s{^([/]+)}{} )
	{
		if( $1 eq '/' )
		{
			$abs_filename = File::Spec->rel2abs( $filename, $self->RootDir() );
		}
		else # '//'
		{
			$abs_filename	= File::Spec->catfile( '/', $filename );
		}
	}
	else
	{
		$abs_filename = File::Spec->rel2abs( $filename, $self->DocumentDir() );
	}
	
	$abs_filename
}


### ##########################################################################

=item	RootDir ( [ $dir ] )

Explicitly set root dir name.

=cut

### --------------------------------------------------------------------------
sub		RootDir
### --------------------------------------------------------------------------
{
	my( $self, $dir )=@_;
	
	if( $dir )
	{
		$self->{RootDir}	= File::Spec->rel2abs( $dir );
	}
	$self->{RootDir}
}


### ##########################################################################

=item	DocumentDir ( [ $dir ] )

Explicitly set document dir name.

=cut

### --------------------------------------------------------------------------
sub		DocumentDir
### --------------------------------------------------------------------------
{
	my( $self, $dir )=@_;
	
	if( $dir )
	{
		$self->{DocumentDir}	= File::Spec->rel2abs( $dir );
	}
	$self->{DocumentDir}
}


=back

=cut


1;

__DATA__

__END__

### //////////////////////////////////////////////////////////////////////////
#
#	SECTION: TODO
#


=head1 TODO	

1. modules inclusion - a) inclusion, b) hook points

2. multiple templates support for different content types - html, wap, txt, ...

=cut
