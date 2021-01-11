#!/Users/yuji/.rbenv/shims/ruby
#
# script for preparation of updating manual translation for Maxima
# author: ICHIKAWA, Yuji

$newdir="#{ENV['HOME']}/Downloads/maxima-5.43.0/doc/info/"
$olddir="#{ENV['HOME']}/Downloads/maxima-5.42.2/doc/info/"
$translateddir="#{ENV['HOME']}/Projects/maxima-manual/maxima-5.42.2/doc/info/"

def treat_file(e)
    old = $olddir + e
    if File.exist?(old)
      diff = `diff #{e} #{old}`
      if $?.success?
        puts 'The file ' + e + ' has no change.'
      else
        puts 'The file ' + e + ' has following modifications.'
        puts diff
        `mv #{e} #{e + '.org'}`
      end
      `cp #{$translateddir + e} .`
    else
      puts 'The file ' + e + ' is new.'
    end
end

Dir.chdir($newdir)
Dir['*.{texi,texi.in}'].each do |e|
    treat_file e
end

Dir['extract_categories*.*'].each do |e|
    treat_file e
end

treat_file 'texi2html.init.in'

`cp #{$translateddir + 'Translator.texi'} .`
