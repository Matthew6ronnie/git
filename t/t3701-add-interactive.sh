# This function uses a trick to manipulate the interactive add to use color:
# the `want_color()` function special-cases the situation where a pager was
# spawned and Git now wants to output colored text: to detect that situation,
# the environment variable `GIT_PAGER_IN_USE` is set. However, color is
# suppressed despite that environment variable if the `TERM` variable
# indicates a dumb terminal, so we set that variable, too.

force_color () {
	env GIT_PAGER_IN_USE=true TERM=vt100 "$@"
}

test_expect_success 'add untracked (multiple)' '
	test_when_finished "git reset && rm [1-9]" &&
	touch $(test_seq 9) &&
	test_write_lines a "2-5 8-" | git add -i -- [1-9] &&
	test_write_lines 2 3 4 5 8 9 >expected &&
	git ls-files [1-9] >output &&
	test_cmp expected output
'

test_expect_success 'different prompts for mode change/deleted' '
	git reset --hard &&
	>file &&
	>deleted &&
	git add --chmod=+x file deleted &&
	echo changed >file &&
	rm deleted &&
	test_write_lines n n n |
	git -c core.filemode=true add -p >actual &&
	sed -n "s/^\(([0-9/]*) Stage .*?\).*/\1/p" actual >actual.filtered &&
	cat >expect <<-\EOF &&
	(1/1) Stage deletion [y,n,q,a,d,?]?
	(1/2) Stage mode change [y,n,q,a,d,j,J,g,/,?]?
	(2/2) Stage this hunk [y,n,q,a,d,K,g,/,e,?]?
	EOF
	test_cmp expect actual.filtered
'

test_expect_success 'correct message when there is nothing to do' '
	git reset --hard &&
	git add -p 2>err &&
	test_i18ngrep "No changes" err &&
	printf "\\0123" >binary &&
	git add binary &&
	printf "\\0abc" >binary &&
	git add -p 2>err &&
	test_i18ngrep "Only binary files changed" err
'

		sed -n -e "s/^([1-2]\/[1-2]) Stage this hunk[^@]*\(@@ .*\)/\1/" \