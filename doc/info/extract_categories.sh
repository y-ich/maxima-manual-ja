TARGET=$1
if [ "x$TARGET" = "x" ]; then
  echo USAGE: sh $0 '<TARGET>'
  exit 1
fi

# Uncomment to see everything as it happens.
# set -x

TARGET_TEXI=$TARGET.texi

WORKING_DIRECTORY=`mktemp -d ${TMPDIR:-/tmp}/maxima-texinfo-categories-XXXXXX`
cp -R *.texi figures $WORKING_DIRECTORY
d=`pwd`
cd $WORKING_DIRECTORY

# Remove the working directory when we're done.
trap "rm -r $WORKING_DIRECTORY" 0

for f in *.texi; do
  if [ $f = "maxima.texi" ]
    then echo SKIP OVER $f
    else
      sed  's/^@deffn  *{[^}]*}  *\([^[:blank:]]*\).*/@anchor{Item: \1}\
&/; s/^@defvr  *{[^}]*}  *\([^[:blank:]]*\).*/@anchor{Item: \1}\
&/; s/^@node  *\([^,]*\).*/@anchor{Item: \1}\
&/' "$f" > tmp.texi
      mv tmp.texi "$f"
    fi
done

cat *.texi\
  | awk '!/^@c / && !/^@c$/ && (/^@deffn/ || /^@defvr/ || /^@end deffn/ || /^@end defvr/ || /@category/ || /@node/)'\
  | sed  's/\$/---endofline---/'\
  | sed  -f "$d/extract_categories1.sed" \
  | awk -F'$' -f "$d/extract_categories1.awk" \
  | sed  's/---endofline---/$/'\
  > tmp-make-categories.py

${PYTHONBIN:-python} tmp-make-categories.py

sed  's/^@bye//' $TARGET_TEXI > tmp-target.texi
echo '@node Documentation Categories' >> tmp-target.texi
echo '@chapter Documentation Categories' >> tmp-target.texi
for f in Category-*.texi; do echo '@include' $f; done >> tmp-target.texi
echo '@bye' >> tmp-target.texi
mv tmp-target.texi $TARGET_TEXI

# Show these two commands because this is where many warnings come from.
set -x
/Users/yuji/OpenSources/texi2html-1.76/texi2html --lang=en --output=maxima_singlepage.html \
 --css-include="$d/manual.css" --init-file "$d/texi2html.init" $TARGET_TEXI
/Users/yuji/OpenSources/texi2html-1.76/texi2html -split_chapter --lang=en --output=. \
 --css-include="$d/manual.css" --init-file "$d/texi2html.init" $TARGET_TEXI
set +x

# Now clean up the texi2html output. I'm going to burn in Hell for this (and much else).

for f in *.html
do
    grep -q '<a href=".*">Category: .*</a>' $f
    if [ $? = 0 ]; then
        echo FIX UP CATEGORY BOXES IN $f
        sed  's/^&middot;$//; s/<p>\(<a href=".*">Category: .*<\/a>\)/<p>Categories:\&nbsp;\&nbsp;\1/' $f > tmp.html
        mv tmp.html $f
    fi
done

for f in *.html
do
    grep -q '<a href=".*">Category: .*</a>' $f
    if [ $? = 0 ]; then
        echo FIX UP CATEGORY HREFS IN $f
        sed  's/<a href="\(.*\)">Category: \(.*\)<\/a>/<a href="\1">\2<\/a>/' $f > tmp.html
        mv tmp.html $f
    fi
done

for f in *.html
do
    grep -q '<a href=".*">Item: .*</a>' $f
    if [ $? = 0 ]; then
        echo FIX UP ITEM HREFS IN $f
        sed  's/<a href="\(.*\)">Item: \(.*\)<\/a>/<a href="\1">\2<\/a>/' $f > tmp.html
        mv tmp.html $f
    fi
done

for f in *.html
do
    grep -q '<meta http-equiv="Content-Type" content="text/html; charset=us-ascii">' $f
    if [ $? = 0 ]; then
        echo FIX UP META CHARSET IN $f
        sed  's/charset=us-ascii/charset=utf-8/' $f > tmp.html
        mv tmp.html $f
    fi
done

mv *.html "$d"

cd "$d"
set +x
