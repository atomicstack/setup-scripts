#!/usr/bin/env perl

use 5.14.2;
use warnings;

# use JSON::XS;
use Cwd;
use Data::Dumper qw/Dumper/;
use File::Basename qw/basename/;
use File::Copy qw/cp/;
use File::Find qw//;
use File::Temp qw//;
use LWP::UserAgent;
use Net::GitHub;
use Time::HiRes qw//;

################################################################################
################################################################################

my $UA_STRING  = '@atomicstack/fzf-binary-fetcher';
my $ARCH       = $ENV{MY_ARCH} // qx{uname -m};
my $GITHUB_KEY = $ENV{GITHUB_KEY} or die 'no $GITHUB_KEY in %ENV!';

chomp $ARCH;

my $START_DIR = Cwd::getcwd();

my $ua = LWP::UserAgent->new(
  agent       => $UA_STRING,
  cookie_jar  => {},
  keep_alive  => 4,
  timeout     => 60,
);

my $github = Net::GitHub->new(
  access_token => $GITHUB_KEY,
  ua           => $ua,
);

################################################################################
################################################################################

my @releases = $github->repos->releases(junegunn => 'fzf')
  or die "no releases found for junegunn/fzf?!";

my $release = $releases[0];
my $release_version = $release->{name}
  or die "couldn't find release_version in the release!";

my $release_assets = $release->{assets}
  or die "no assets found for latest release?!";

my $arch_regexp = make_filename_regexp();

# say "\$\^O: $^O, \$arch_regexp: $arch_regexp";

my ($binary_asset) = grep { $_->{name} =~ $arch_regexp } @$release_assets;

defined($binary_asset)
  or die "couldn't find binary asset for MY_OS=$^O, MY_ARCH=$ARCH";

my $binary_asset_name = $binary_asset->{name};

say "found binary asset for MY_OS=$^O, MY_ARCH=$ARCH: $binary_asset_name (release=$release_version)";

my $download_url = $binary_asset->{browser_download_url};
say "fetching download_url=$download_url";

my $fetch_response = $ua->get($download_url);

$fetch_response->is_success or die sprintf(
  "non-200 while fetching url=%s, status_code=%d",
  $download_url,
  $fetch_response->code,
);

my $temp_dir = File::Temp->newdir();
say "temp_dir=$temp_dir";
chdir "$temp_dir";
IO::File->new($binary_asset_name => 'w')->print($fetch_response->decoded_content);
my $decompressed_files = decompress_file($temp_dir, $binary_asset_name);
chdir $START_DIR;

my ($path_to_fzf_binary) = grep { basename($_) eq 'fzf' } @$decompressed_files;
my $fzf_destination_path = "$ENV{HOME}/git_tree/fzf/bin/fzf";
cp($path_to_fzf_binary, $fzf_destination_path);
link $fzf_destination_path, "$fzf_destination_path-${release_version}";

say "created $fzf_destination_path (and $fzf_destination_path-$release_version)";
say "run the following to symlink fzf and its extras into place:";
say "mkdir -vp /usr/local/share/fzf"
say "ln -svf $ENV{HOME}/git_tree/fzf/bin/fzf{,-tmux} /usr/local/bin/";
say "ln -svf $ENV{HOME}/git_tree/fzf/{plugin,shell}/* /usr/local/share/fzf/";

################################################################################
################################################################################

sub make_filename_regexp {

  my %arch_regexps = (
    aarch64 => qr/(?:aarch64|arm64)/ixms,
    arm64   => qr/(?:aarch64|arm64)/ixms,
    x86_64  => qr/(?:x86_64|amd64)/ixms,
    amd64   => qr/(?:x86_64|amd64)/ixms,
    default => qr//,
  );

  my $normalised_regexp = $arch_regexps{$ARCH} // $arch_regexps{default};

  my $arch_regexp = qr/${^O} [_] $normalised_regexp/ixms;

  return $arch_regexp;
}

################################################################################
################################################################################

sub decompress_file {
  my ($dir, $compressed_file) = @_;

  if ($compressed_file =~ m/[.]zip$/ixms) {
    system "unzip $compressed_file";
  }
  elsif ($compressed_file =~ m/[.]tar[.](?:gz|bz2?)$/ixms) {
    system "tar xf $compressed_file";
  }
  else {
    my $filename = basename($compressed_file);
    die "decompress_file(): don't know how to handle decompressing $filename";
  }

  my @decompressed_files;

  my $find_callback = sub {
    return unless -f ( my $f = $File::Find::name );
    push @decompressed_files => $f;
  };

  File::Find::find( $find_callback => $dir);
  say "found these files after decompression: @decompressed_files";

  return \@decompressed_files;
}
