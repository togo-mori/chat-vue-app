require 'rails_helper'

RSpec.describe "ChatGroups", type: :system do
  before do
    @chat_group = build(:chat_group)
  end

  describe "正常形" do
    context "グループ一覧表示(同期)" do
      it "root_pathにアクセスすると既に登録してあるチャットグループの情報が表示される" do
        @chat_group.save 

      end

      it "グループが登録されていないときサイドバーにはグループ情報が表示されていない" do
        
      end
      
      
      
    end

    context "グループ新規作成成功" do
      it "グループ名を入力して作成ボタンを押すと非同期でグループが作成され、作成したチャットグループのページに遷移する。
      また、サイドバーの一番下に作成したグループのページを見るためのリンクが設置される。" do 
        # 新規作成したグループが複数あるデータの一番下に来ることを検証するためにデータを挿入
        another_group = create(:chat_group, group_name: 'another_test')
        visit root_path
        expect(page).to  have_selector '.group-name', text: ""
        expect(page).to  have_button '+'
        click_button '+'
        expect(page).to  have_content 'チャットグループ新規作成'
        fill_in "group_name_input",	with: @chat_group.group_name
        expect do 
          click_button '作成'
          sleep 1 #sleepがないとmysqlの処理が追いつかない
        end.to change(ChatGroup, :count).by(1)
        expect(page).to  have_selector '.group-name', text: @chat_group.group_name 
        #同じ名前のグループが作成されたときにこの検証だとやや弱い気がしている
        expect(
          all('.group-list-item p')[-1].text 
        ).to  eq @chat_group.group_name
        # サイドバーの一番下にあるpタグのテキストが作成したグループ名と一致することを検証
      end
      
    end
    
    context "モーダルウィンドウの開閉" do

      context "新規グループ作成" do
        # 編集のときも考慮してcontext作成
        before do
          visit root_path
          expect(page).to  have_button '+'
          click_button '+'
        end
        
        it "モーダルウィンドウ内部をクリックしてもモーダルウィンドウが開いたままである" do 
          find("#content").click
          expect(page).to  have_content 'チャットグループ新規作成'
        end
        
        it "closeボタンをクリックするとモーダルウィンドウを閉じる" do
          click_button 'close', id: 'close_button'
          expect(page).to have_no_content 'チャットグループ新規作成'
        end
        
        it "モーダルウィンドウ外部をクリックするとモーダルウィンドウが閉じる" do
          find("#overlay").click
          expect(page).to  have_content 'チャットグループ新規作成'
        end
        
      end
      
    end

    context "グループの情報の取得(同期)" do
      it "URLを直接入力して/#/chat_groups/:idにアクセスすると現在アクセスしているグループの情報が取得できる" do
        visit root_path
        @chat_group.save
        visit "/#/chat_groups/#{@chat_group.id}" #vue-routerで設定したパスなのでprefixが存在しない
        expect(page).to have_selector '.group-name', text: @chat_group.group_name  
      end
      
    end
  end
  

  describe "異常形" do
    
    context "グループ新規作成失敗" do
      it "グループ名が空のままフォームを送信するとエラーメッセージが表示され、モーダルウィンドウが開いたままであること" do 
        visit root_path
        expect(page).to  have_selector '.group-name', text: ""
        expect(page).to  have_button '+'
        click_button '+'
        expect(page).to  have_content 'チャットグループ新規作成'
        fill_in "group_name_input",	with: ""
        expect do 
          click_button '作成'
        end.to change(ChatGroup, :count).by(0)
        expect(page).to  have_content 'チャットグループ新規作成' #モーダルウィンドウにとどまっていることを検証
        expect(page).to  have_selector '.error-messages', text: "Group name can't be blank" #エラーメッセージの表示を確認
      end
      
    end

    context "グループ情報取得失敗" do
      it "グループのidが存在しないときグループ情報が取得できず、アラートが出る" do
        visit root_path
        expect do
          visit "/#/chat_groups/#{@chat_group.id}" 
          sleep 2
          expect(page.driver.browser.switch_to.alert.text).to eq "不正なidです"
          sleep 1
          page.driver.browser.switch_to.alert.accept
          sleep 1
          page.raise_server_error! #手動でサーバーエラーを発生させることで実行環境と同様のエラーを得る
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
  
end