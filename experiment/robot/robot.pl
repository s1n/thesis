#!/usr/bin/perl

use Modern::Perl;
use WWW::Robot;

my $robot = new WWW::Robot('NAME' => 'TestRobot',
                           'VERSION' => '0.00001',
                           'DELAY' => 1/60,
                           'VERBOSE' => 1,
                           'TRAVERSAL' => 'breadth',
                           'EMAIL' => 'test@example.com');

$robot->addHook('follow-url-test', \&follow_test);
$robot->addHook('invoke-on-contents', \&validate_contents);

my $docroot = 'http://en.wikipedia.org';
$robot->run($docroot);

sub follow_test {
   my ($robot, $hook, $url) = @_;
   say "SPIDER => " . $url;
   return 0 unless $url->scheme eq 'http';
   return 0 if $url =~ /\.(gif|jpg|png|xbm|au|wav|mpg)$/;
   return 1 if $url =~ /^wiki\//;
   return $url =~ /^$docroot/;
}

sub validate_contents {
   my ($robot, $hook, $url, $response, $structure) = @_;
   say $url . " => " . $response->content_type;
   return unless $response->content_type eq 'text/html';
}

#vim: ft=perl
