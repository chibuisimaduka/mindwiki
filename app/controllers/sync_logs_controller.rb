# The MIT License
# 
# Copyright (c) 2009 Sami Blommendahl, Mika Hannula, Ville Kivelä,
# Aapo Laitinen, Matias Muhonen, Anssi Männistö, Samu Ollila, Jukka Peltomäki,
# Matias Piipari, Lauri Renko, Aapo Tahkola, and Juhani Tamminen.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
class SyncLogsController < ApplicationController

  def time_now
    t = Time.now
    return t.gmtime # Rails timestamps are in GMT
  end

  def check_for_updates
    respond_to do |format|
      if params[:id].nil? || params[:timestamp].nil?
        format.js { render :json => { :err => 1 }.to_json, :status => :unprocessable_entity }
      else
        @now = time_now()
        if !params[:timestamp].empty?
          # graph_id = NULL means we push the update to all clients regardless of active graph
          @updates = SyncLog.find(:all, :order => "created_at ASC", :conditions => [ "created_at >= ? AND created_at < ? AND (graph_id = ? OR graph_id IS NULL)", params[:timestamp], @now, params[:id]])
          #@debug = { :timestamp => params[:timestamp], :now => @now, :gid => params[:id] }
          @graph = Graph.find(:first, :conditions => ["id = ?", params[:id]]) # find(params[:id]) raises a RecordNotFound error upon deleted graph
          if !@graph.nil? and @updates.count > 0
            @exts = @graph.get_extents
          end
        else
          @exts = ""
          @updates = ""
          #@debug = ""
          # With an OK timestamp but no updates, the response is "exts: null and updates: []"
        end
        format.js { 
          # Give the client the timestamp we used as an upper bound, and also the results
          @updates_and_timestamp = "{\"time\": "+@now.to_s(:db).to_json+", \"extents\": "+@exts.to_json+", \"updates\": "+@updates.to_json+"}"
          render :json => @updates_and_timestamp 
        }
      end
    end
  end

end
