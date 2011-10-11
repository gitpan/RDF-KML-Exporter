package RDF::KML::Exporter;

use 5.010;
use common::sense;

use Geo::GoogleEarth::Pluggable;
use RDF::TrineShortcuts qw[:all];
use Scalar::Util qw[blessed];

sub GEO  { return 'http://www.w3.org/2003/01/geo/wgs84_pos#' . shift; }
sub RDFS { return 'http://www.w3.org/2000/01/rdf-schema#' . shift; }

use namespace::clean;

our $VERSION = '0.002';

sub new
{
	my ($class, %options) = @_;
	bless { %options }, $class;
}

sub export_kml
{
	my ($self, $model, %options) = @_;
	$model = RDF::TrineShortcuts::rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');

	my $kml = Geo::GoogleEarth::Pluggable->new;
	
	my @subjects = $model->subjects;
	S: foreach my $s (@subjects)
	{
		my @latitudes  = grep
				{ $_->is_literal }
				$model->objects_for_predicate_list($s,
					rdf_resource(GEO('lat')),
					);
		next S unless @latitudes;
		my $lat  = flatten_node($latitudes[0]);
		
		my @longitudes = grep
				{ $_->is_literal }
				$model->objects_for_predicate_list($s,
					rdf_resource(GEO('long')),
					);
		next S unless @longitudes;
		my $long = flatten_node($longitudes[0]);
		
		my @altitudes = grep
				{ $_->is_literal }
				$model->objects_for_predicate_list($s,
					rdf_resource(GEO('alt')),
					);
		my $alt = flatten_node($altitudes[0], passthrough_undef => 1);

		my @labels = grep
			{ $_->is_literal }
			$model->objects_for_predicate_list($s,
				rdf_resource('http://www.geonames.org/ontology#name'),
				rdf_resource('http://www.w3.org/2004/02/skos/core#prefLabel'),
				rdf_resource(RDFS('label')),
				rdf_resource('http://xmlns.com/foaf/0.1/name'),
#				rdf_resource('http://www.w3.org/2004/02/skos/core#altLabel'),
#				rdf_resource('http://www.w3.org/2004/02/skos/core#notation'),
				);
		my $label = flatten_node($labels[0], passthrough_undef => 1);

		my %info = (lat=>$lat, lon=>$long);
		$info{name} ||= $label if defined $label;
		$info{alt}  ||= $alt   if defined $alt;
		
		$kml->Point(%info);
	}
	
	return $kml;
}

1;

__END__

=head1 NAME

RDF::KML::Exporter - export RDF geo data to KML (Google Earth)

=head1 SYNOPSIS

 use RDF::KML::Exporter;
 
 my $exporter = RDF::KML::Exporter->new;
 my $input    = 'http://dbpedia.org/resource/Lewes';
 
 print $exporter->export_kml($input)->render;

=head1 DESCRIPTION

=head2 Constructor

=over

=item * C<< new(%options) >>

Returns a new RDF::KML::Exporter object.

There are no valid options at the moment - the hash is reserved
for future use.

=back

=head2 Methods

=over

=item * C<< export_kml($input, %options) >>

Returns a KML document including all the locations in the input,
in no particular order.

The input may be a URI, file name, L<RDF::Trine::Model> or anything else
that can be handled by the C<rdf_parse> method of L<RDF::TrineShortcuts>.

The returned object is an L<Geo::GoogleEarth::Pluggable> instance, which
can be output as XML using its C<render> method.

=back

=head2 RDF Input

Input is expected to use the W3C's WGS84 Geo Positioning vocabulary
L<http://www.w3.org/2003/01/geo/wgs84_pos#>. Place names should use
rdfs:label.

=head1 SEE ALSO

L<HTML::Microformats>, L<RDF::TrineShortcuts>,
L<Geo::GoogleEarth::Pluggable>.

L<http://www.w3.org/2003/01/geo/wgs84_pos#>.

L<http://www.perlrdf.org/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

