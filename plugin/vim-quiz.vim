""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim global plugin for short description
" Maintainer:	Barry Arthur <barry.arthur@gmail.com>
" Version:	0.1
" Description:	Demo application for the tiktok timer library
" Last Change:	2012-11-04
" License:	Vim License (see :help license)
" Location:	plugin/vim-quiz.vim
" Website:	https://github.com/dahu/vim-quiz
"
" See vim-quiz.txt for help.  This can be accessed by doing:
"
" :helptags ~/.vim/doc
" :help vim-quiz
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:vim_quiz_version = '0.1'

" Vimscript Setup: {{{1
" Allow use of line continuation.
let s:save_cpo = &cpo
set cpo&vim

" load guard
" uncomment after plugin development
"if exists("g:loaded_vim_quiz")
"      \ || v:version < 700
"      \ || v:version == 703 && !has('patch338')
"      \ || &compatible
"  let &cpo = s:save_cpo
"  finish
"endif
"let g:loaded_vim_quiz = 1

" Colours: {{{1

hi def CorrectAnswer   ctermfg=green guifg=green
hi def IncorrectAnswer ctermfg=red guifg=red

" Private Functions: {{{1

function! s:QuizData()
  let b:deck = {
        \ 'timeout': 10,
        \ 'questions': [
        \   {'q': "How do you move forward a word?", 'a': 'w'},
        \   {'q': "How do you move backward a word?", 'a': 'b'},
        \   {'q': "How do you move to the end of the prior word?", 'a': 'ge'}
        \ ]
        \}
endfunction

function! s:Submit()
  call s:LocateAnswerLine()
  let answer = substitute(substitute(getline('.'), '^Answer: \s*', '', ''), '\s*$', '', '')
  if answer =~ b:deck.questions[b:qnum].a
    call s:CorrectAnswer()
  else
    call s:IncorrectAnswer()
  endif
  call s:NextQuestion()
endfunction

function! s:CorrectAnswer()
  let b:score += 10
  echohl CorrectAnswer
  echo "Correct!"
  echohl None
endfunction

function! s:IncorrectAnswer()
  call append('$', ['', "Correct Answer: " . b:deck.questions[b:qnum].a])
  redraw
  echohl IncorrectAnswer
  echo "Incorrect!"
  echohl None
  call b:timer.toggle()
  call input("Ok")
  call b:timer.toggle()
endfunction

function! s:NextQuestion()
  let b:qnum += 1
  if b:qnum < len(b:deck.questions)
    call s:Render()
    call s:LocateAnswerLine()
    startinsert
  else
    call b:timer.stop()
    %delete
    call setline(1, ["Quiz Finished",
          \ '',
          \ "Questions: " . b:qnum,
          \ "  Correct: " . (b:score/10),
          \ "    Score: " . b:score,
          \])
  endif
endfunction

function! s:LocateAnswerLine()
  call search('^Answer:\s*', 'e')
endfunction

function! s:Render()
  %delete
  call s:TimeRemaining()
  call s:QuestionNumber()
  call s:Score()
  call s:Newline()
  call s:Question()
  call s:Newline()
  call s:AnswerPrompt()
endfunction

function! s:Newline()
  call append('$', '')
endfunction

function! s:Question()
  call append('$', "Question: " . b:deck.questions[b:qnum].q)
endfunction

function! s:AnswerPrompt()
  call append('$', "Answer:  ")
endfunction

function! s:TimeRemaining()
  call setline(1, "Time      : " . b:deck.timeout)
endfunction

function! s:QuestionNumber()
  call append('$', "Question #: " . (b:qnum + 1))
endfunction

function! s:Score()
  call append('$', "Score     : " . b:score)
endfunction

function! s:QuizBanner()
  %delete
  append
   #####
  #     #  #    #     #    ######
  #     #  #    #     #        #
  #     #  #    #     #       #
  #   # #  #    #     #      #
  #    #   #    #     #     #
   #### #   ####      #    ######

  Press ENTER to begin
.
  redraw
  call input('')
endfunction

" Public Interface: {{{1

function! CountdownTimer()
  let countdown_line = getline(1)
  if countdown_line =~ ':\s*\d\+$'
    call setline(1, substitute(countdown_line, '\d\+', '\=submatch(0)-1', ''))
  endif
endfunction

function! CountdownTimerExpired()
  if match(getline(1), '\D\@<=0$') != -1
    call setline(1, substitute(getline(1), '\d\+', '10', ''))
    call s:Submit()
  endif
endfunction

function! StartVimQuiz()
  if ! exists('*tiktok#timer')
    echo "Vim-Quiz requires https://github.com/dahu/tiktok"
    return
  endif

  " scratch buffer
  silent! enew
  silent! only
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile

  let b:timer = tiktok#timer()
  call b:timer.register('CountdownTimer')
  call b:timer.register('CountdownTimerExpired')

  nnoremap <leader>p :call b:timer.toggle()<cr>
  inoremap <buffer> <cr> <esc>:call <SID>Submit()<cr>

  call s:QuizData()
  call s:QuizBanner()
  let b:score = 0
  let b:qnum = -1
  call s:NextQuestion()
  call b:timer.start()

  let b:tiktok_pid = system(findfile('bin/tiktok', &rtp).' vimquiz "b:timer.tick()" &')

  augroup VIMQUIZ
    au!
    au VimLeave * call system("kill " . b:tiktok_pid)
  augroup END
endfunction

" Commands: {{{1
command! -nargs=0 StartVimQuiz call StartVimQuiz()

" Teardown:{{{1
"reset &cpo back to users setting
let &cpo = s:save_cpo

" vim: set sw=2 sts=2 et fdm=marker:
