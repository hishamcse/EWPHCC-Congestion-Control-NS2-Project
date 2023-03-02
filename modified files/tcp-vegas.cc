/* -*-	Mode:C++; c-basic-offset:8; tab-width:8; indent-tabs-mode:t -*- */

/*
 * tcp-vegas.cc
 * Copyright (C) 1997 by the University of Southern California
 * $Id: tcp-vegas.cc,v 1.37 2005/08/25 18:58:12 johnh Exp $
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
 *
 *
 * The copyright of this module includes the following
 * linking-with-specific-other-licenses addition:
 *
 * In addition, as a special exception, the copyright holders of
 * this module give you permission to combine (via static or
 * dynamic linking) this module with free software programs or
 * libraries that are released under the GNU LGPL and with code
 * included in the standard release of ns-2 under the Apache 2.0
 * license or under otherwise-compatible licenses with advertising
 * requirements (or modified versions of such code, with unchanged
 * license).  You may copy and distribute such a system following the
 * terms of the GNU GPL for this module and the licenses of the
 * other code concerned, provided that you include the source code of
 * that other code when and as the GNU GPL requires distribution of
 * source code.
 *
 * Note that people who make modified versions of this module
 * are not obligated to grant this special exception for their
 * modified versions; it is their choice whether to do so.  The GNU
 * General Public License gives permission to release a modified
 * version without this exception; this exception also makes it
 * possible to release a modified version which carries forward this
 * exception.
 *
 */

/*
 * ns-1 implementation:
 *
 * This is an implementation of U. of Arizona's TCP Vegas. I implemented
 * it based on USC's NetBSD-Vegas.
 *					Ted Kuo
 *					North Carolina St. Univ. and
 *					Networking Software Div, IBM
 *					tkuo@eos.ncsu.edu
 */

#ifndef lint
static const char rcsid[] =
"@(#) $Header: /cvsroot/nsnam/ns-2/tcp/tcp-vegas.cc,v 1.37 2005/08/25 18:58:12 johnh Exp $ (NCSU/IBM)";
#endif

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/types.h>

#include "ip.h"
#include "tcp.h"
#include "flags.h"

#define MIN(x, y) ((x)<(y) ? (x) : (y))


static class VegasTcpClass : public TclClass {
public:
	VegasTcpClass() : TclClass("Agent/TCP/Vegas") {}
	TclObject* create(int, const char*const*) {
		return (new VegasTcpAgent());
	}
} class_vegas;


VegasTcpAgent::VegasTcpAgent() : TcpAgent()
{
	v_sendtime_ = NULL;
	v_transmits_ = NULL;
}

VegasTcpAgent::~VegasTcpAgent()
{
	if (v_sendtime_)
		delete []v_sendtime_;
	if (v_transmits_)
		delete []v_transmits_;
}

void
VegasTcpAgent::delay_bind_init_all()
{
	delay_bind_init_one("v_alpha_");
	delay_bind_init_one("v_beta_");
	delay_bind_init_one("v_gamma_");
	delay_bind_init_one("v_rtt_");
	TcpAgent::delay_bind_init_all();
        reset();
}

int
VegasTcpAgent::delay_bind_dispatch(const char *varName, const char *localName, 
				   TclObject *tracer)
{
	/* init vegas var */
        if (delay_bind(varName, localName, "v_alpha_", &v_alpha_, tracer)) 
		return TCL_OK;
        if (delay_bind(varName, localName, "v_beta_", &v_beta_, tracer)) 
		return TCL_OK;
        if (delay_bind(varName, localName, "v_gamma_", &v_gamma_, tracer)) 
		return TCL_OK;
        if (delay_bind(varName, localName, "v_rtt_", &v_rtt_, tracer)) 
		return TCL_OK;
        return TcpAgent::delay_bind_dispatch(varName, localName, tracer);
}

void
VegasTcpAgent::reset()
{
	t_cwnd_changed_ = 0.;
	firstrecv_ = -1.0;
	v_slowstart_ = 2;
	v_sa_ = 0;
	v_sd_ = 0;
	v_timeout_ = 1000.;
	v_worried_ = 0;
	v_begseq_ = 0;
	v_begtime_ = 0.;
	v_cntRTT_ = 0; v_sumRTT_ = 0.;
	v_baseRTT_ = 1000000000.;
	v_incr_ = 0;
	v_inc_flag_ = 1;

    // modified part
	v_impact_factor_ = 0.8;     // assigning impact factor
	v_prev_rtt_ = 0.0;          // previous rtt
	v_prev_delay_prob_ = 0.0;
	v_loss_count_ = 0;
	v_est_loss_prob_ = 0.0;
	v_target_loss_window_ = cwnd_;
	v_target_delay_window_ = cwnd_;

	TcpAgent::reset();
}

void
VegasTcpAgent::recv_newack_helper(Packet *pkt)
{
	newack(pkt);
#if 0
	// like TcpAgent::recv_newack_helper, but without this
	if ( !hdr_flags::access(pkt)->ecnecho() || !ecn_ ) {
	        opencwnd();
	}
#endif
	/* if the connection is done, call finish() */
	if ((highest_ack_ >= curseq_-1) && !closed_) {
		closed_ = 1;
		finish();
	}
}

void
VegasTcpAgent::old_algorithm(Packet *pkt, Handler *)
{
	double currentTime = vegastime();
	hdr_tcp *tcph = hdr_tcp::access(pkt);
	hdr_flags *flagh = hdr_flags::access(pkt);

#if 0
	if (pkt->type_ != PT_ACK) {
		Tcl::instance().evalf("%s error \"recieved non-ack\"",
				      name());
		Packet::free(pkt);
		return;
	}
#endif /* 0 */
	++nackpack_;

	if(firstrecv_<0) { // init vegas rtt vars
		firstrecv_ = currentTime;
		v_baseRTT_ = v_rtt_ = firstrecv_;
		v_sa_  = v_rtt_ * 8.;
		v_sd_  = v_rtt_;
		v_timeout_ = ((v_sa_/4.)+v_sd_)/2.;
	}

	if (flagh->ecnecho())
		ecn(tcph->seqno());
	if (tcph->seqno() > last_ack_) {
		if (last_ack_ == 0 && delay_growth_) {
			cwnd_ = initial_window();
		}
		/* check if cwnd has been inflated */
		if(dupacks_ > numdupacks_ &&  cwnd_ > v_newcwnd_) {
			cwnd_ = v_newcwnd_;
			// vegas ssthresh is used only during slow-start
			ssthresh_ = 2;
		}
		int oldack = last_ack_;

		recv_newack_helper(pkt);
		
		/*
		 * begin of once per-rtt actions
		 * 	1. update path fine-grained rtt and baseRTT
		 *      2. decide what to do with cwnd_, inc/dec/unchanged
		 *         based on delta=expect - actual.
		 */
		if(tcph->seqno() >= v_begseq_) {
			double rtt;
			if(v_cntRTT_ > 0)
				rtt = v_sumRTT_ / v_cntRTT_;
			else 
				rtt = currentTime - v_begtime_;

			v_sumRTT_ = 0.0;
			v_cntRTT_ = 0;

			// calc # of packets in transit
			int rttLen = t_seqno_ - v_begseq_;

			/*
			 * decide should we incr/decr cwnd_ by how much
			 */
			if(rtt>0) {
				/* if there's only one pkt in transit, update 
			 	 * baseRTT
			 	 */
				if(rtt<v_baseRTT_ || rttLen<=1)
					v_baseRTT_ = rtt;

				double expect;   // in pkt/sec
				// actual = (# in transit)/(current rtt) 
				v_actual_ = double(rttLen)/rtt;
				// expect = (current window size)/baseRTT
				expect = double(t_seqno_-last_ack_)/v_baseRTT_;

				// calc actual and expect thruput diff, delta
				int delta=int((expect-v_actual_)*v_baseRTT_+0.5);
				if(cwnd_ < ssthresh_) { // slow-start
					// adj cwnd every other rtt
					v_inc_flag_ = !v_inc_flag_;
					if(!v_inc_flag_)
						v_incr_ = 0;
					else {
					    if(delta > v_gamma_) {
						// slow-down a bit to ensure
						// the net is not so congested
						ssthresh_ = 2;
						cwnd_-=(cwnd_/8);
						if(cwnd_<2)
							cwnd_ = 2.;
						v_incr_ = 0;
					    } else 
						v_incr_ = 1;
					}
				} else { // congestion avoidance
					if(delta>v_beta_) {
						/*
						 * slow down a bit, retrack
						 * back to prev. rtt's cwnd
						 * and dont incr in the nxt rtt
						 */
						--cwnd_;
						if(cwnd_<2) cwnd_ = 2;
						v_incr_ = 0;
					} else if(delta<v_alpha_)
						// delta<alpha, faster....
						v_incr_ = 1/cwnd_;
					else // current rate is cool.
						v_incr_ = 0;
				}
			} // end of if(rtt > 0)

			// tag the next packet 
			v_begseq_ = t_seqno_; 
			v_begtime_ = currentTime;
		} // end of once per-rtt section

		/* since we set how much to incr only once per rtt,
		 * need to check if we surpass ssthresh during slow-start
		 * before the rtt is over.
		 */		
		if(v_incr_ == 1 && cwnd_ >= ssthresh_)
			v_incr_ = 0;
		
		/*
		 * incr cwnd unless we havent been able to keep up with it
		 */
		if(v_incr_>0 && (cwnd_-(t_seqno_-last_ack_))<=2)
			cwnd_ = cwnd_+v_incr_;	

		// Add to make Vegas obey maximum congestion window variable.
		if (maxcwnd_ && (int(cwnd_) > maxcwnd_)) {
			cwnd_ = maxcwnd_;
		}

		/*
		 * See if we need to update the fine grained timeout value,
		 * v_timeout_
		 */

		// reset v_sendtime for acked pkts and incr v_transmits_
		double sendTime = v_sendtime_[tcph->seqno()%v_maxwnd_];
		int transmits = v_transmits_[tcph->seqno()% v_maxwnd_];
		int range = tcph->seqno() - oldack;
		for(int k=((oldack+1) %v_maxwnd_); 
			k<=(tcph->seqno()%v_maxwnd_) && range >0 ; 
			k=((k+1) % v_maxwnd_), range--) {
			v_sendtime_[k] = -1.0;
			v_transmits_[k] = 0;
		}

		if((sendTime !=0.) && (transmits==1)) {
			 // update fine-grained timeout value, v_timeout_.
			double rtt, n;
			rtt = currentTime - sendTime;
			v_sumRTT_ += rtt;
			++v_cntRTT_;
			if(rtt>0) {
				v_rtt_ = rtt;
				if(v_rtt_ < v_baseRTT_)
					v_baseRTT_ = v_rtt_;
				n = v_rtt_ - v_sa_/8;
				v_sa_ += n;
				n = n<0 ? -n : n;
				n -= v_sd_ / 4;
				v_sd_ += n;
				v_timeout_ = ((v_sa_/4)+v_sd_)/2;
				v_timeout_ += (v_timeout_/16);
			}
		}

		/* 
		 * check the 1st or 2nd acks after dup ack received 
		 */
		if(v_worried_>0) {
			/*
			 * check if any pkt has been timeout. if so, 
			 * retx it. no need to change cwnd since we
			 * already did.
			 */
			--v_worried_;
			int expired=vegas_expire(pkt);
			if(expired>=0) {
				dupacks_ = numdupacks_;
				output(expired, TCP_REASON_DUPACK);
			} else
				v_worried_ = 0;
		}
   	} else if (tcph->seqno() == last_ack_)  {
		/* check if a timeout should happen */
		++dupacks_; 
		int expired=vegas_expire(pkt);
		if (expired>=0 || dupacks_ == numdupacks_) {
			double sendTime=v_sendtime_[(last_ack_+1) % v_maxwnd_]; 
			int transmits=v_transmits_[(last_ack_+1) % v_maxwnd_];
       	                /* The line below, for "bug_fix_" true, avoids
                        * problems with multiple fast retransmits after
			* a retransmit timeout.
                        */
			if ( !bug_fix_ || (highest_ack_ > recover_) || \
			    ( last_cwnd_action_ != CWND_ACTION_TIMEOUT)) {
				int win = window();
				last_cwnd_action_ = CWND_ACTION_DUPACK;
				recover_ = maxseq_;
				/* check for timeout after recv a new ack */
				v_worried_ = MIN(2, t_seqno_ - last_ack_ );
		
				/* v_rto expon. backoff */
				if(transmits > 1) 
					v_timeout_ *=2.; 
				else
					v_timeout_ += (v_timeout_/8.);
				/*
				 * if cwnd hasnt changed since the pkt was sent
				 * we need to decr it.
				 */
				if(t_cwnd_changed_ < sendTime ) {
					if(win<=3)
						win=2;
					else if(transmits > 1)
						win >>=1;
					else 
						win -= (win>>2);

					// record cwnd_
					v_newcwnd_ = double(win);
					// inflate cwnd_
					cwnd_ = v_newcwnd_ + dupacks_;
					t_cwnd_changed_ = currentTime;
				} 

				// update coarser grained rto
				reset_rtx_timer(1);
				if(expired>=0) 
					output(expired, TCP_REASON_DUPACK);
				else
					output(last_ack_ + 1, TCP_REASON_DUPACK);
					 
				if(transmits==1) 
					dupacks_ = numdupacks_;
                        }
		} else if (dupacks_ > numdupacks_) 
			++cwnd_;
	}
	Packet::free(pkt);

#if 0
	if (trace_)
		plot();
#endif /* 0 */

	/*
	 * Try to send more data
	 */
	if (dupacks_ == 0 || dupacks_ > numdupacks_ - 1)
		send_much(0, 0, maxburst_);
}

void
VegasTcpAgent::new_algorithm(Packet *pkt, Handler *)
{
	double currentTime = vegastime();
	hdr_tcp *tcph = hdr_tcp::access(pkt);
	hdr_flags *flagh = hdr_flags::access(pkt);


#if 0
	if (pkt->type_ != PT_ACK) {
		Tcl::instance().evalf("%s error \"recieved non-ack\"",
				      name());
		Packet::free(pkt);
		return;
	}
#endif /* 0 */
	++nackpack_;

	if(firstrecv_<0) { // init vegas rtt vars
		firstrecv_ = currentTime;
		v_baseRTT_ = v_rtt_ = firstrecv_;
		v_sa_  = v_rtt_ * 8.;
		v_sd_  = v_rtt_;
		v_timeout_ = ((v_sa_/4.)+v_sd_)/2.;

		// modified part
		v_impact_factor_ = 0.8;     
		v_prev_rtt_ = 0.0;
	    v_prev_delay_prob_ = 0.0;
		v_loss_count_ = 0;
		v_est_loss_prob_ = 0.0;
		v_target_loss_window_ = cwnd_;
		v_target_delay_window_ = cwnd_;
	}

	if (flagh->ecnecho())
		ecn(tcph->seqno());
	if (tcph->seqno() > last_ack_) {
		if (last_ack_ == 0 && delay_growth_) {
			cwnd_ = initial_window();

			// modified part
			v_target_loss_window_ = cwnd_;
		}
		/* check if cwnd has been inflated */
		if(dupacks_ > numdupacks_ &&  cwnd_ > v_newcwnd_) {
			cwnd_ = v_newcwnd_;
			// vegas ssthresh is used only during slow-start
			ssthresh_ = 2;
		}
		int oldack = last_ack_;

		recv_newack_helper(pkt);
		
		/*
		 * begin of once per-rtt actions
		 * 	1. update path fine-grained rtt and baseRTT
		 *      2. decide what to do with cwnd_, inc/dec/unchanged
		 *         based on delta=expect - actual.
		 */
		if(tcph->seqno() >= v_begseq_) {
			double rtt;
			double delay_i;
			double delay_queue = 0.0;

			if(v_cntRTT_ > 0) {
				rtt = v_sumRTT_ / v_cntRTT_;

                /* Modification Start */

				// estimate queue delay
				delay_i = (double) v_rtt_ * 2.0 / cwnd_;
				delay_queue = rtt - v_baseRTT_;
				delay_queue = delay_queue < 0 ? -delay_queue : delay_queue;
				// printf("delay_queue = %lf\n", delay_queue);

				/* Modification End */
			} else 
				rtt = currentTime - v_begtime_;

			v_sumRTT_ = 0.0;
			v_cntRTT_ = 0;

			// calc # of packets in transit
			int rttLen = t_seqno_ - v_begseq_;

			/*
			 * decide should we incr/decr cwnd_ by how much
			 */
			if(rtt>0) {
				/* if there's only one pkt in transit, update 
			 	 * baseRTT
			 	 */
				if(rtt<v_baseRTT_ || rttLen<=1)
					v_baseRTT_ = rtt;

				double expect;   // in pkt/sec
				// actual = (# in transit)/(current rtt) 
				v_actual_ = double(rttLen)/rtt;
				// expect = (current window size)/baseRTT
				expect = double(t_seqno_-last_ack_)/v_baseRTT_;

				// calc actual and expect thruput diff, delta
				int delta=int((expect-v_actual_)*v_baseRTT_+0.5);

                /* Modification start */
				v_incr_ = 0;    // for safety if we don't assign it
				/*Modification End*/

				if(cwnd_ < ssthresh_) { // slow-start
					// adj cwnd every other rtt
					v_inc_flag_ = !v_inc_flag_;
					if(!v_inc_flag_)
						v_incr_ = 0;
					else {
					    if(delta > v_gamma_) {
						// slow-down a bit to ensure
						// the net is not so congested
						ssthresh_ = 2;
						cwnd_-=(cwnd_/8);
						if(cwnd_<2)
							cwnd_ = 2.;
						v_incr_ = 0;
					    } else 
						v_incr_ = 1;
					}
				} else { // congestion avoidance
				    
					 ///////////////////////////////// modification starts /////////////////////////////////

					// threshold min value of delay
					double min_threshold = ssthresh_ / expect;
					// printf("min_threshold = %lf\n", min_threshold);

					double delay = (double) 2.0 * v_rtt_ / cwnd_;
					// printf("delay = %lf\n", delay);

                    double min_delay = (double) 2.0 * v_baseRTT_ /  cwnd_;
					// printf("min_delay = %lf\n", min_delay);
					
					double bfs_delay = (double) (expect - v_actual_) * min_delay;
					// printf("bfs_delay = %lf\n", bfs_delay);

					double loss = (double) v_rtt_ * v_loss_count_ /  cwnd_;
					// printf("loss = %lf\n", loss*100.0);

					double min_loss = (double) v_baseRTT_ * v_loss_count_ /  cwnd_;
					// printf("min_loss = %lf\n", min_loss);

					double bfs_loss = (double) (expect - v_actual_) * min_loss;
					// printf("bfs_loss = %lf\n", bfs_loss);
					
					int select_phase = (bfs_delay != 0 && bfs_loss != 0 && delay_queue != 0 &&
					                 delay >= min_threshold) ? 1 : 0;

					if(select_phase == 0) {
						// printf("normal\n");

						cwnd_ *= 2.0;
					} else {

						// printf("hello\n");

                        double threshold_delay = double(t_seqno_-last_ack_) * ((delay - min_delay) / bfs_delay);
						threshold_delay = threshold_delay < 0 ? -threshold_delay : threshold_delay;
						// printf("threshold_delay = %lf\n", threshold_delay);

						double threshold_loss = double(t_seqno_-last_ack_) * ((loss - min_loss) / bfs_loss);
						threshold_loss = threshold_loss < 0 ? -threshold_loss : threshold_loss;
						// printf("threshold_loss = %lf\n", threshold_loss);

						double max_threshold = threshold_delay > threshold_loss ? threshold_delay : threshold_loss;
						// printf("max_threshold = %lf\n", max_threshold);

						if(delay < max_threshold) {   // congestion control phase
							// printf("congestion control\n");
                            
							// estimate delay probability using EWMA method
							double est_delay_prob = v_impact_factor_ * v_prev_delay_prob_ + (1.0 - v_impact_factor_) * v_prev_rtt_;
							// printf("est_delay = %lf\n", est_delay_prob);

							v_prev_delay_prob_ = est_delay_prob;
							v_prev_rtt_ = v_rtt_;

							// printf("window size = %lf\n", cwnd_.value());

							// calculate target window size
							double alpha = cwnd_ / v_rtt_;
							// printf("alpha = %lf\n", alpha);

							v_target_delay_window_ = (delay_i * alpha) / delay_queue;
							// printf("v_target_delay_window_ = %lf\n", v_target_delay_window_);
					
							double est_window_incr_delay = (1.0 - est_delay_prob) * v_target_delay_window_;
							est_window_incr_delay = est_window_incr_delay < 0 ? -est_window_incr_delay : est_window_incr_delay;
							
							// printf("prev_est_loss = %lf\n", v_est_loss_prob_);
							double est_window_incr_loss = (1.0 - v_est_loss_prob_) * v_target_loss_window_;
							est_window_incr_loss = est_window_incr_loss < 0 ? -est_window_incr_loss : est_window_incr_loss;

							double est_window_incr = sqrt((est_window_incr_delay * est_window_incr_delay + est_window_incr_loss * est_window_incr_loss) / 2.0);
							// printf("sqrt_avg = %lf\n", est_window_incr);

							// double avg = (est_window_incr_delay + est_window_incr_loss) / 2.0;
							// printf("avg = %lf\n", avg);

							double estimated_window = cwnd_ + est_window_incr;
							// printf("new window = %lf\n", estimated_window);

							// update window size
							cwnd_ = estimated_window;			
							// v_newcwnd_ = cwnd_;		

						} else if(delay >= max_threshold && delay < v_timeout_) {   // critical phase
							// printf("critical\n");
							
							cwnd_ -= v_alpha_;
							if(cwnd_< 2.0) cwnd_ = 2.0;

						} else {                    // timeout or loss phase
							// printf("timeout\n");
							cwnd_ /= 2.0;
						}
					}
				}

				//////////////////////////// modification ends ////////////////////////////
			} // end of if(rtt > 0)

			// tag the next packet 
			v_begseq_ = t_seqno_; 
			v_begtime_ = currentTime;
		} // end of once per-rtt section

		/* since we set how much to incr only once per rtt,
		 * need to check if we surpass ssthresh during slow-start
		 * before the rtt is over.
		 */		
		if(v_incr_ == 1 && cwnd_ >= ssthresh_)
			v_incr_ = 0;
		
		/*
		 * incr cwnd unless we havent been able to keep up with it
		 */
		if(v_incr_>0 && (cwnd_-(t_seqno_-last_ack_))<=2)
			cwnd_ = cwnd_+v_incr_;	

		// // Add to make Vegas obey maximum congestion window variable.
		// if (maxcwnd_ && (int(cwnd_) > maxcwnd_)) {
		// 	cwnd_ = maxcwnd_;
		// }

		/*
		 * See if we need to update the fine grained timeout value,
		 * v_timeout_
		 */

		// reset v_sendtime for acked pkts and incr v_transmits_
		double sendTime = v_sendtime_[tcph->seqno()%v_maxwnd_];
		int transmits = v_transmits_[tcph->seqno()% v_maxwnd_];
		int range = tcph->seqno() - oldack;
		for(int k=((oldack+1) %v_maxwnd_); 
			k<=(tcph->seqno()%v_maxwnd_) && range >0 ; 
			k=((k+1) % v_maxwnd_), range--) {
			v_sendtime_[k] = -1.0;
			v_transmits_[k] = 0;
		}

		if((sendTime !=0.) && (transmits==1)) {
			 // update fine-grained timeout value, v_timeout_.
			double rtt, n;
			rtt = currentTime - sendTime;
			v_sumRTT_ += rtt;
			++v_cntRTT_;
			if(rtt>0) {
				v_rtt_ = rtt;
				if(v_rtt_ < v_baseRTT_)
					v_baseRTT_ = v_rtt_;
				n = v_rtt_ - v_sa_/8;
				v_sa_ += n;
				n = n<0 ? -n : n;
				n -= v_sd_ / 4;
				v_sd_ += n;
				v_timeout_ = ((v_sa_/4)+v_sd_)/2;
				v_timeout_ += (v_timeout_/16);
			}
		}

		/* 
		 * check the 1st or 2nd acks after dup ack received 
		 */
		if(v_worried_>0) {
			/*
			 * check if any pkt has been timeout. if so, 
			 * retx it. no need to change cwnd since we
			 * already did.
			 */
			--v_worried_;
			int expired=vegas_expire(pkt);
			if(expired>=0) {

				dupacks_ = numdupacks_;
				output(expired, TCP_REASON_DUPACK);
			} else
				v_worried_ = 0;
		}
   	} else if (tcph->seqno() == last_ack_)  {
		/* check if a timeout should happen */
		++dupacks_; 
		int expired=vegas_expire(pkt);
		if (expired>=0 || dupacks_ == numdupacks_) {

			double sendTime=v_sendtime_[(last_ack_+1) % v_maxwnd_]; 
			int transmits=v_transmits_[(last_ack_+1) % v_maxwnd_];
       	                /* The line below, for "bug_fix_" true, avoids
                        * problems with multiple fast retransmits after
			* a retransmit timeout.
                        */
			if ( !bug_fix_ || (highest_ack_ > recover_) || \
			    ( last_cwnd_action_ != CWND_ACTION_TIMEOUT)) {
				int win = window();
				last_cwnd_action_ = CWND_ACTION_DUPACK;
				recover_ = maxseq_;
				/* check for timeout after recv a new ack */
				v_worried_ = MIN(2, t_seqno_ - last_ack_ );
		
				/* v_rto expon. backoff */
				if(transmits > 1) 
					v_timeout_ *=2.; 
				else
					v_timeout_ += (v_timeout_/8.);
				/*
				 * if cwnd hasnt changed since the pkt was sent
				 * we need to decr it.
				 */
				if(t_cwnd_changed_ < sendTime ) {
					if(win<=3)
						win=2;
					else if(transmits > 1)
						win >>=1;
					else 
						win -= (win>>2);

					// record cwnd_
					v_newcwnd_ = double(win);
					// inflate cwnd_
					cwnd_ = v_newcwnd_ + dupacks_;
					t_cwnd_changed_ = currentTime;
				} 

				// update coarser grained rto
				reset_rtx_timer(1);
				if(expired>=0) 
					output(expired, TCP_REASON_DUPACK);
				else
					output(last_ack_ + 1, TCP_REASON_DUPACK);
					 
				if(transmits==1) 
					dupacks_ = numdupacks_;
                        }
		} else if (dupacks_ > numdupacks_) 
			++cwnd_;
	}
	Packet::free(pkt);

#if 0
	if (trace_)
		plot();
#endif /* 0 */

	/*
	 * Try to send more data
	 */
	if (dupacks_ == 0 || dupacks_ > numdupacks_ - 1)
		send_much(0, 0, maxburst_);
}

void
VegasTcpAgent::recv(Packet *pkt, Handler *h)
{
    // old_algorithm(pkt, h);
	new_algorithm(pkt, h);
}

void
VegasTcpAgent::timeout(int tno)
{

	if (tno == TCP_TIMER_RTX) {
		if (highest_ack_ == maxseq_ && !slow_start_restart_) {
			/*
			 * TCP option:
			 * If no outstanding data, then don't do anything.
			 *
			 * Note:  in the USC implementation,
			 * slow_start_restart_ == 0.
			 * I don't know what the U. Arizona implementation
			 * defaults to.
			 */
			return;
		};
		dupacks_ = 0;
		recover_ = maxseq_;
		last_cwnd_action_ = CWND_ACTION_TIMEOUT;
		reset_rtx_timer(0);
		++nrexmit_;
		slowdown(CLOSE_CWND_RESTART|CLOSE_SSTHRESH_HALF);
		cwnd_ = double(v_slowstart_);
		v_newcwnd_ = 0;
		t_cwnd_changed_ = vegastime();
		send_much(0, TCP_REASON_TIMEOUT);
	} else {
		/* delayed-sent timer, with random overhead to avoid
		 * phase effect. */
		send_much(1, TCP_REASON_TIMEOUT);
	};
}

void
VegasTcpAgent::output(int seqno, int reason)
{
	Packet* p = allocpkt();
	hdr_tcp *tcph = hdr_tcp::access(p);
	double now = Scheduler::instance().clock();
	tcph->seqno() = seqno;
	tcph->ts() = now;
	tcph->reason() = reason;

	/* if this is the 1st pkt, setup senttime[] and transmits[]
	 * I alloc mem here, instrad of in the constructor, to cover
	 * cases which windows get set by each different tcp flows */
	if (seqno==0) {
		v_maxwnd_ = int(wnd_);
		if (v_sendtime_)
			delete []v_sendtime_;
        	if (v_transmits_)
               		delete []v_transmits_;
		v_sendtime_ = new double[v_maxwnd_];
		v_transmits_ = new int[v_maxwnd_];
		for(int i=0;i<v_maxwnd_;i++) {
			v_sendtime_[i] = -1.;
			v_transmits_[i] = 0;
		}
	}

	// record a find grained send time and # of transmits 
	int index = seqno % v_maxwnd_;
	v_sendtime_[index] = vegastime();  
	++v_transmits_[index];

	/* support ndatabytes_ in output - Lloyd Wood 14 March 2000 */
	int bytes = hdr_cmn::access(p)->size(); 
	ndatabytes_ += bytes; 
	ndatapack_++; // Added this - Debojyoti 12th Oct 2000
	send(p, 0);
	if (seqno == curseq_ && seqno > maxseq_)
		idle();  // Tell application I have sent everything so far

	if (seqno > maxseq_) {
		maxseq_ = seqno;
		if (!rtt_active_) {
			rtt_active_ = 1;
			if (seqno > rtt_seq_) {
				rtt_seq_ = seqno;
				rtt_ts_ = now;
			}
		}
	} else {
		++nrexmitpack_;
       		nrexmitbytes_ += bytes;
    	}

	if (!(rtx_timer_.status() == TIMER_PENDING))
		/* No timer pending.  Schedule one. */
		set_rtx_timer();
}

/*
 * return -1 if the oldest sent pkt has not been timeout (based on
 * fine grained timer).
 */
int
VegasTcpAgent::vegas_expire(Packet* pkt)
{

	hdr_tcp *tcph = hdr_tcp::access(pkt);
	double elapse = vegastime() - v_sendtime_[(tcph->seqno()+1)%v_maxwnd_];
	if (elapse >= v_timeout_) {

		// modified part for loss
		v_loss_count_++;

		v_est_loss_prob_ = v_impact_factor_ * v_est_loss_prob_ + 
		                      (1.0 - v_impact_factor_) * double(v_loss_count_ / elapse);
		// printf("est_loss = %lf\n", v_est_loss_prob_);

        // v_target_loss_window_ = cwnd_;

		// end of modified part for loss

		return(tcph->seqno()+1);
	}
	return(-1);
}

