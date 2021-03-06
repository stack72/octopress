require 'bundler/setup'
require 'sinatra/base'
require 'rack-rewrite'

# The project root directory
$root = ::File.dirname(__FILE__)

use Rack::Rewrite do
  r301 %r{^/blog/?$}, "/"
  r301 %r{^/post/why-delay-the-vs2012-release-microsoft.aspx/?$}, "/blog/2012/08/09/why-delay-the-vs2012-release-microsoft/"
  r301 %r{^/post/survival-of-the-fittest-fluid-teams.aspx/?$}, "/blog/2012/06/25/survival-of-the-fittest-fluid-teams/"
  r301 %r{^/post/tfs-and-continuous-deployment.aspx/?$}, "/blog/2012/06/19/tfs-and-continuous-deployment/"
  r301 %r{^/post/what-is-your-interpretation-of-burnout.aspx/?$}, "/blog/2012/06/07/what-is-your-interpretation-of-burnout/"
  r301 %r{^/post/teamcity-outofmemoryerror.aspx/?$}, "/blog/2012/05/21/teamcity-outofmemoryerror/"
  r301 %r{^/post/introducing-teamcity-metro.aspx/?$}, "/blog/2012/05/17/introducing-teamcity-metro/"
  r301 %r{^/post/enum-string-value-for-use-with-jquery-mobile.aspx/?$}, "/blog/2012/05/03/enum-string-value-for-use-with-jquery-mobile/"
  r301 %r{^/post/you-think-im-doing-it-wrong-so-help-me-do-it-right.aspx/?$}, "/blog/2012/05/01/you-think-im-doing-it-wrong-so-help-me-do-it-right/"
  r301 %r{^/post/spoofing-the-host-entry-in-a-httpwebrequest.aspx/?$}, "/blog/2012/04/30/spoofing-the-host-entry-in-a-httpwebrequest/"
  r301 %r{^/post/my-approach-to-refactoring-a-monster-switch-statement.aspx/?$}, "/blog/2012/04/15/my-approach-to-refactoring-a-monster-switch-statement/"
  r301 %r{^/post/custom-blogging-workflow-with-youtrack.aspx/?$}, "/blog/2012/04/09/custom-blogging-workflow-with-youtrack/"
  r301 %r{^/post/agile-teams-and-working-from-home.aspx/?$}, "/blog/2012/04/03/agile-teams-and-working-from-home/"
  r301 %r{^/post/teamcitysharp-now-builds-with-mono.aspx/?$}, "/blog/2012/02/08/teamcitysharp-now-builds-with-mono/"
  r301 %r{^/post/installing-mono-on-windows.aspx/?$}, "/blog/2012/01/31/installing-mono-on-windows/"
  r301 %r{^/post/how-nuget-could-improve.aspx/?$}, "/blog/2012/01/17/how-nuget-could-improve/"
  r301 %r{^/post/codemash-2012-truly-awesome.aspx/?$}, "/blog/2012/01/14/codemash-2012-truly-awesome/"
  r301 %r{^/post/2011-my-year-in-review.aspx/?$}, "/blog/2011/12/29/features-nuget-would-benefit-from/"
  r301 %r{^/post/features-nuget-would-benefit-from.aspx/?$}, "/blog/2011/12/29/2011-my-year-in-review/"
  r301 %r{^/post/memory-management-in-net-story-board.aspx/?$}, "/blog/2011/12/19/memory-management-in-net-story-board/"
  r301 %r{^/post/teamcitysharp-v02.aspx/?$}, "/blog/2011/11/30/teamcitysharp-v02/"
  r301 %r{^/post/teamcity-pricing-model-discussion.aspx/?$}, "/blog/2011/11/29/teamcity-pricing-model-discussion/"
  r301 %r{^/post/introducing-teamcitysharp.aspx/?$}, "/blog/2011/11/24/introducing-teamcitysharp/"
  r301 %r{^/post/is-implementing-continuous-delivery-the-key-to-success.aspx/?$}, "/blog/2011/11/10/is-implementing-continuous-delivery-the-key-to-success/"
  r301 %r{^/post/html5-clean-code-for-front-end-developers.aspx/?$}, "/blog/2011/10/31/html5-clean-code-for-front-end-developers/"
  r301 %r{^/post/controlling-iis7-programmatically.aspx/?$}, "/blog/2011/10/16/controlling-iis7-programmatically/"
  r301 %r{^/post/automated-w3c-validation-with-teamcity.aspx/?$}, "/blog/2011/10/11/automated-w3c-validation-with-teamcity/"
  r301 %r{^/post/is-sql-the-barrier-to-continuous-deployment.aspx/?$}, "/blog/2011/09/28/is-sql-the-barrier-to-continuous-deployment/"
  r301 %r{^/post/tfs-vnext-falls-short-of-the-mark.aspx/?$}, "/blog/2011/09/20/tfs-vnext-falls-short-of-the-mark/"
  r301 %r{^/post/why-you-shouldnt-feel-nervous-about-givecampuk.aspx/?$}, "/blog/2011/09/10/why-you-shouldnt-feel-nervous-about-givecampuk/"
  r301 %r{^/post/strategy-to-make-ci-builds-self-testing.aspx/?$}, "/blog/2011/08/31/strategy-to-make-ci-builds-self-testing/"
  r301 %r{^/post/is-it-really-agile.aspx/?$}, "/blog/2011/08/22/is-it-really-agile/"
  r301 %r{^/post/implementing-your-first-project-into-a-ci-system.aspx/?$}, "/blog/2011/08/17/implementing-your-first-project-into-a-ci-system/"
  r301 %r{^/post/have-orms-introduced-extra-complexity-into-our-codebase.aspx/?$}, "/blog/2011/08/13/have-orms-introduced-extra-complexity-into-our-codebase/"
  r301 %r{^/post/win-a-ticket-to-progressivenet-tutorials.aspx/?$}, "/blog/2011/08/09/win-a-ticket-to-progressivenet-tutorials/"
  r301 %r{^/post/feature-switching-a-better-way-to-collaborate.aspx/?$}, "/blog/2011/08/04/feature-switching-a-better-way-to-collaborate/"
  r301 %r{^/post/choosing-the-correct-ci-tool.aspx/?$}, "/blog/2011/08/03/choosing-the-correct-ci-tool/"
  r301 %r{^/post/progressive-dotnet-at-skillsmatter.aspx/?$}, "/blog/2011/07/27/progressive-dotnet-at-skillsmatter/"
  r301 %r{^/post/development-key-skills-or-lack-of-them.aspx/?$}, "/blog/2011/07/18/development-key-skills-or-lack-of-them/"
  r301 %r{^/post/easy-http-not-just-a-catchy-name.aspx/?$}, "/blog/2011/07/15/easy-http-not-just-a-catchy-name/"
  r301 %r{^/post/iis-rewrite-tool-the-pain-of-a-simple-rule-change.aspx/?$}, "/blog/2011/07/11/iis-rewrite-tool-the-pain-of-a-simple-rule-change/"
  r301 %r{^/post/considerations-when-choosing-hardware-for-ci.aspx/?$}, "/blog/2011/07/06/considerations-when-choosing-hardware-for-ci/"
  r301 %r{^/post/satisfyr-useful-little-addition-to-my-testing.aspx/?$}, "/blog/2011/07/04/satisfyr-useful-little-addition-to-my-testing/"
  r301 %r{^/post/mocks-stubs-a-thing-of-the-past.aspx/?$}, "/blog/2011/06/30/mocks-stubs-a-thing-of-the-past/"
  r301 %r{^/post/how-to-get-started-with-ci.aspx/?$}, "/blog/2011/06/28/how-to-get-started-with-ci/"
  r301 %r{^/post/continuous-delivery-is-not-continuous-deployment.aspx/?$}, "/blog/2011/06/20/continuous-delivery-is-not-continuous-deployment/"
  r301 %r{^/post/ingredients-needed-for-an-effective-team.aspx/?$}, "/blog/2011/06/15/ingredients-needed-for-an-effective-team/"
  r301 %r{^/post/review-of-ddd-guathon-2.aspx/?$}, "/blog/2011/06/06/review-of-ddd-guathon-2/"
  r301 %r{^/post/dont-hate-the-player-hate-the-game.aspx/?$}, "/blog/2011/06/03/dont-hate-the-player-hate-the-game/"
  r301 %r{^/post/givecamp-is-coming-to-the-uk!.aspx/?$}, "/blog/2011/05/27/givecamp-is-coming-to-the-uk%21/"
  r301 %r{^/post/best-recruitment-drive-ever!.aspx/?$}, "/blog/2011/05/25/best-recruitment-drive-ever%21/"
  r301 %r{^/post/is-webmatrix-a-threat-to-the-professional-developer.aspx/?$}, "/blog/2011/05/16/is-webmatrix-a-threat-to-the-professional-developer/"
  r301 %r{^/post/attribute-based-caching-with-postsharp.aspx/?$}, "/blog/2011/05/10/attribute-based-caching-with-postsharp/"
  r301 %r{^/post/free-speaker-training-day.aspx/?$}, "/blog/2011/05/09/free-speaker-training-day/"
  r301 %r{^/post/ddd-scotland-2011.aspx/?$}, "/blog/2011/05/08/ddd-scotland-2011/"
  r301 %r{^/post/sql-ce-4-database-scripting.aspx/?$}, "/blog/2011/04/14/sql-ce-4-database-scripting/"
  r301 %r{^/post/ddd-southwest-get-ready-to-register.aspx/?$}, "/blog/2011/04/12/ddd-southwest-get-ready-to-register/"
  r301 %r{^/post/using-sql-compare-from-the-command-line.aspx/?$}, "/blog/2011/04/07/using-sql-compare-from-the-command-line/"
  r301 %r{^/post/using-add-deployable-dependencies-in-vs2010-sp1.aspx/?$}, "/blog/2011/04/05/using-add-deployable-dependencies-in-vs2010-sp1/"
  r301 %r{^/post/iis-rewrite-module-and-mvc3.aspx/?$}, "/blog/2011/04/05/iis-rewrite-module-and-mvc3/"
  r301 %r{^/post/extracting-a-sql-server-schema-from-sql-server-ce-file.aspx/?$}, "/blog/2011/03/26/extracting-a-sql-server-schema-from-sql-server-ce-file/"
  r301 %r{^/post/teamcity-iis-seo-toolkit.aspx/?$}, "/blog/2011/03/23/teamcity-iis-seo-toolkit/"
  r301 %r{^/post/finally-a-visual-studio-extension-sync-tool.aspx/?$}, "/blog/2011/03/20/finally-a-visual-studio-extension-sync-tool/"
  r301 %r{^/post/using-razor-to-clean-up-my-scripts-and-styles.aspx/?$}, "/blog/2011/03/18/using-razor-to-clean-up-my-scripts-and-styles/"
  r301 %r{^/post/microsoft-release-ie9.aspx/?$}, "/blog/2011/03/15/microsoft-release-ie9/"
  r301 %r{^/post/ddd-scotland-e28093-registration-almost-open!.aspx/?$}, "/blog/2011/03/13/ddd-scotland-e28093-registration-almost-open%21/"
  r301 %r{^/post/how-to-install-teamcity-6x-plugins.aspx/?$}, "/blog/2011/03/13/how-to-install-teamcity-6x-plugins/"
  r301 %r{^/post/how-i-disconnect-stop-myself-burning-out.aspx/?$}, "/blog/2011/03/07/how-i-disconnect-stop-myself-burning-out/"
  r301 %r{^/post/running-powershell-scripts-from-teamcity.aspx/?$}, "/blog/2011/02/28/running-powershell-scripts-from-teamcity/"
  r301 %r{^/post/review-azure-in-action.aspx/?$}, "/blog/2011/02/22/review-azure-in-action/"
  r301 %r{^/post/how-to-debug-msbuild-files-in-vs2010.aspx/?$}, "/blog/2011/02/19/how-to-debug-msbuild-files-in-vs2010/"
  r301 %r{^/post/postsharp-and-teamcity-integration.aspx/?$}, "/blog/2011/02/11/postsharp-and-teamcity-integration/"
  r301 %r{^/post/visual-studio-2010-extension-required.aspx/?$}, "/blog/2011/02/04/visual-studio-2010-extension-required/"
  r301 %r{^/post/how-i-enjoyed-ddd9.aspx/?$}, "/blog/2011/01/31/how-i-enjoyed-ddd9/"
  r301 %r{^/post/differences-between-specflow-and-cuke4nuke.aspx/?$}, "/blog/2011/01/24/differences-between-specflow-and-cuke4nuke/"
  r301 %r{^/post/error-in-android-21.aspx/?$}, "/blog/2011/01/22/error-in-android-21/"
  r301 %r{^/post/what-passion-means-to-me.aspx/?$}, "/blog/2011/01/21/what-passion-means-to-me/"
  r301 %r{^/post/where-have-all-the-good-developers-gone.aspx/?$}, "/blog/2011/01/17/where-have-all-the-good-developers-gone/"
  r301 %r{^/post/the-nightmare-when-i-upgraded-my-mvc2-solution-to-mvc3.aspx/?$}, "/blog/2011/01/15/the-nightmare-when-i-upgraded-my-mvc2-solution-to-mvc3/"
  r301 %r{^/post/moving-from-cuke4nuke-to-specflow.aspx/?$}, "/blog/2011/01/12/moving-from-cuke4nuke-to-specflow/"
  r301 %r{^/post/review-soa-patterns.aspx/?$}, "/blog/2011/01/11/review-soa-patterns/"
  r301 %r{^/post/visual-studio-2010-bug.aspx/?$}, "/blog/2010/12/22/visual-studio-2010-bug/"
  r301 %r{^/post/macosx-theme-for-win7-laptop.aspx/?$}, "/blog/2010/12/14/macosx-theme-for-win7-laptop/"
  r301 %r{^/post/upgrading-from-teamcity-5x-to-60.aspx/?$}, "/blog/2010/12/14/upgrading-from-teamcity-5x-to-60/"
  r301 %r{^/post/why-scrum-doesne28099t-suit-me-but-kanban-does.aspx/?$}, "/blog/2010/11/26/why-scrum-doesne28099t-suit-me-but-kanban-does/"
  r301 %r{^/post/review-of-nosql-day-at-dundee-university.aspx/?$}, "/blog/2010/11/21/review-of-nosql-day-at-dundee-university/"
  r301 %r{^/post/firebreake28093my-thoughts.aspx/?$}, "/blog/2010/11/17/firebreake28093my-thoughts/"
  r301 %r{^/post/review-hello!-silverlight.aspx/?$}, "/blog/2010/10/27/review-hello%21-silverlight/"
  r301 %r{^/post/getting-started-with-simpledata.aspx/?$}, "/blog/2010/10/18/getting-started-with-simpledata/"
  r301 %r{^/post/simpledata-e28093-a-new-wave-of-orm.aspx/?$}, "/blog/2010/10/15/simpledata-e28093-a-new-wave-of-orm/"
  r301 %r{^/post/tool-of-the-week-e28093-console-e28093-151010.aspx/?$}, "/blog/2010/10/15/tool-of-the-week-e28093-console-e28093-151010/"
  r301 %r{^/post/review-dependency-injection-in-net.aspx/?$}, "/blog/2010/10/09/review-dependency-injection-in-net/"
  r301 %r{^/post/tool-of-the-week-e28093-programmers-notepad2-e28093-100910.aspx/?$}, "/blog/2010/09/13/tool-of-the-week-e28093-programmers-notepad2-e28093-100910/"
  r301 %r{^/post/review-continuous-integration-in-net.aspx/?$}, "/blog/2010/08/31/review-continuous-integration-in-net/"
  r301 %r{^/post/guathon-london-august-2010.aspx/?$}, "/blog/2010/08/14/guathon-london-august-2010/"
  r301 %r{^/post/breaking-the-dependency.aspx/?$}, "/blog/2010/08/09/breaking-the-dependency/"
  r301 %r{^/post/iis-administration-application.aspx/?$}, "/blog/2010/07/29/iis-administration-application/"
  r301 %r{^/post/all-change-please!.aspx/?$}, "/blog/2010/07/27/all-change-please%21/"
  r301 %r{^/post/my-ddd-south-west-review.aspx/?$}, "/blog/2010/06/07/my-ddd-south-west-review/"
  r301 %r{^/post/speed-of-for-loop-vs-for-each-loop.aspx/?$}, "/blog/2010/06/04/speed-of-for-loop-vs-for-each-loop/"
  r301 %r{^/post/how-to-create-and-fill-and-ienumerable3cstring3e.aspx/?$}, "/blog/2010/06/04/how-to-create-and-fill-and-ienumerable3cstring3e/"
  r301 %r{^/post/differences-between-build-automation-and-continuous-integration.aspx/?$}, "/blog/2010/06/01/differences-between-build-automation-and-continuous-integration/"
  r301 %r{^/post/functional-programming-in-net.aspx/?$}, "/blog/2010/04/21/functional-programming-in-net/"
  r301 %r{^/post/iphone-40-announcement.aspx/?$}, "/blog/2010/04/08/iphone-40-announcement/"
  r301 %r{^/post/what-is-microsoftcshaprdll-in-vs2010-rc.aspx/?$}, "/blog/2010/04/07/what-is-microsoftcshaprdll-in-vs2010-rc/"
  r301 %r{^/post/logging-exceptions-via-exceptioneer.aspx/?$}, "/blog/2010/04/07/logging-exceptions-via-exceptioneer/"
  r301 %r{^/post/cuke4nuke-intellisense-for-cuke4vs.aspx/?$}, "/blog/2010/03/23/cuke4nuke-intellisense-for-cuke4vs/"
  r301 %r{^/post/devevening-orm-showdown-feb-25th.aspx/?$}, "/blog/2010/02/25/devevening-orm-showdown-feb-25th/"
  r301 %r{^/post/temp-table-vs-table-variable.aspx/?$}, "/blog/2010/02/23/temp-table-vs-table-variable/"
  r301 %r{^/post/strange-error-in-visual-studio-2010.aspx/?$}, "/blog/2010/02/19/strange-error-in-visual-studio-2010/"
  r301 %r{^/post/welcome-to-my-new-blog.aspx/?$}, "/blog/2010/02/18/welcome-to-my-new-blog/"
  r301 %r{^/post/what-happens-to-watin-tests-when-containers-change.aspx/?$}, "/blog/2010/02/16/what-happens-to-watin-tests-when-containers-change/"
  r301 %r{^/post/automated-ui-testing-part-2-installing-cucumber.aspx/?$}, "/blog/2010/02/09/automated-ui-testing-part-2-installing-cucumber/"
  r301 %r{^/post/visual-studio-2010-release-candidate.aspx/?$}, "/blog/2010/02/09/visual-studio-2010-release-candidate/"
  r301 %r{^/post/automated-ui-testing-part-1-watin.aspx/?$}, "/blog/2010/02/05/automated-ui-testing-part-1-watin/"
  r301 %r{^/post/windows-7.aspx/?$}, "/blog/2009/08/06/windows-7/"
  r301 %r{^/post/uk-citizenship-test.aspx/?$}, "/blog/2009/08/05/uk-citizenship-test/"
  r301 %r{^/post/agile-assessment.aspx/?$}, "/blog/2009/08/03/agile-assessment/"
  r301 %r{^/post/webdd-09.aspx/?$}, "/blog/2009/04/18/webdd-09/"
end

class SinatraStaticServer < Sinatra::Base

  get(/.+/) do
    send_sinatra_file(request.path) {404}
  end

  not_found do
    send_file(File.join(File.dirname(__FILE__), 'public', '404.html'), {:status => 404})
  end

  def send_sinatra_file(path, &missing_file_block)
    file_path = File.join(File.dirname(__FILE__), 'public',  path)
    file_path = File.join(file_path, 'index.html') unless file_path =~ /\.[a-z]+$/i
    File.exist?(file_path) ? send_file(file_path) : missing_file_block.call
  end

end

run SinatraStaticServer
