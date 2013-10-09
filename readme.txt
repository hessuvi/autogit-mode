* autogit-mode for GNU Emacs

Version: alpha - 0.1 (not a true mode yet)
Copyright: Heikki Virtanen (2013)
License: GPL
Homepage: https://github.com/hessuvi/autogit-mode

Purpose: Keep working repository (and opened files) in sync with its
         upstream automatically.

Architecture:
  - Global mode. All open buffers visiting file in git repository are
    tracked by autogit. (Note: Autogit works in local mode, if current
    branch have no upstream set.)

  - Each repository is tracked separately.

Setting up:
  + Ones:
    - git config --global merge.conflictstyle diff3
    - git config --global push.default upstream
      (For older git version (<1.7.5):
           git config --global push.default tracking)

  + For each repository and branch, which are intended to be synced
    automatically:
    - git branch --set-upstream <local session branch> <remote session branch>

Usage:
  - emacs --load <path to autogit.el>
  - autogit works seamlessly in background and no explicit actions are
    needed.

Hints:
  - Be careful with sensitive data! Setup your .gitignore in advance,
    if you do not have any other choice than keeping sensitive data
    within the repository.
  - If git merge --squash is used for integration, new session branch have
    to be created and have to be based on the tip of the integration branch.
  - Magit (http://magit.github.io/magit/) is still useful. This is not
    replacement of any Emacs' VC package.
  - GPG agent can be used as ssh-agent replacement. Advance is that
    private keys are decrypted only when needed.

* Why

Collaboration is one of the key elements of productivity and pleasure.
Unfortunately, web based solutions have many nasty problems. Those lack
decent editing capabilities for text and source code, there is no support
for working off-line, data is stored in dedicated server which is maintained
solely by service provider and it is not possible to set up or buy
independent server sided services, a few to mention.

Git and Emacs with Magit is a handy tool combination and functionally it is
sufficient working environment. However, user experience is still somewhat
clumsy, since staging, committing, pulling, and pushing have to be done
manually over and over again. And it is easy to forget to commit and push
the last modifications of the day. Automation can help on these problems,
so, why not to use it?

* How

Formal methods are seen as a waterfall century dinosaurs and anything but
agile. But have anybody tried to use them in order to make programming more
straightforward and gain development speed? This is small experiment for
that.

There have been following development steps:
1. Identified operating scenarios was combined into a single, transition
   based behavioural model.
2. The model was minimised and validated and verified using Tampere
   Verification Tool and visual verification
   (https://github.com/hessuvi/TampereVerificationTool).
3. The behavioural model, aka state machine, was translated algorithmically
   to Emacs-lisp data structure, which is core of the system. Also, the
   functionality for wandering in the state machine was implemented.
4. The system was first tested with stub functions for the actions.
5. And finally, the actions was implemented and the system was tested in
   real-world conditions.

Unfortunately, all tools used in the development process are not publicly
available yet. One purpose of this project was to test this new development
method and tools supporting it and some new requirements was found. The
auxiliary tools will be released when these new features are decently
implemented.
