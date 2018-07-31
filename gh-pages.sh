git branch -d gh-pages
git checkout -b gh-pages
git add -f Documents
git commit -m 'fix: code style'
git subtree push --prefix Documents origin gh-pages
git checkout master