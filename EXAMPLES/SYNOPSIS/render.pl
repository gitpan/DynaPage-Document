#!/usr/bin/perl

  use DynaPage::Document;
  use DynaPage::Document::ext::include;

  my $doc = DynaPage::Document->new(
    {
      RootDir=>'.',
      Document=>'mydoc-document.info',
    }
  );

 print $doc->Render();
